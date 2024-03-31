#!/bin/bash
# Source the config file
source config.sh

# Function to set proxy configuration in redsocks.conf
function set_proxy_config {
    local ip=$1
    local port=$2
    local type=$3
    local username=$4
    local password=$5
    local config_file=$6

    # Update the redsocks configuration block in the config file
    process_server
    sed -i "s|^\s*ip\s*.*$|        ip = $ip;|" "$config_file"
    sed -i "s|^\s*port\s*.*$|        port = $port;|" "$config_file"
    sed -i "s|^\s*type\s*.*$|        type = $type;|" "$config_file"
    sed -i "s|^\s*login\s*.*$|        login = \"$username\";|" "$config_file"
    sed -i "s|^\s*password\s*.*$|        password = \"$password\";|" "$config_file"
    update_server

}

function process_set_proxy_config {
    read -p "Enter proxy index to set configuration (index): " index
    proxy=$(sed -n "${index}p" "$PROXY_LIST")
    if [[ -n "$proxy" ]]; then
        IFS=':' read -r ip port username password protocol <<< "$proxy"
        set_proxy_config "$ip" "$port" "$protocol" "$username" "$password" "$CONFIG_FILE"
        echo "Proxy configuration set successfully."
    else
        echo "Proxy not found in the list."
    fi
}


# Check if proxy list file exists, if not create one
if [ ! -f "$PROXY_LIST" ]; then
    touch "$PROXY_LIST"
    echo "Proxy list file created: $PROXY_LIST"
fi

function show_proxies {
    echo "Current Proxies:"
    echo " Index | IP                | Port | Username       | Password       | Protocol"
    echo "-------------------------------------------------------------------------------"
    index=1
    while IFS=':' read -r ip port username password protocol || [[ -n $ip ]]; do
        if [ -z "$ip" ]; then
            break
        fi
        printf " %-6s| %-18s| %-5s| %-15s| %-15s| %s\n" "$index" "$ip" "$port" "$username" "$password" "$protocol"
        ((index++))
    done < "$PROXY_LIST"
}

function add_proxy {
    read -p "Enter proxy IP: " ip
    read -p "Enter proxy port: " port
    read -p "Enter proxy username: " username
    read -sp "Enter proxy password: " password
    echo
    read -p "Enter proxy protocol: " protocol
    # Check if all inputs are valid
    if [[ -n $ip && -n $port && -n $protocol ]]; then
        # If all inputs are valid, insert into the proxy list
        echo "$ip:$port:$username:$password:$protocol" >> "$PROXY_LIST"
        echo "Proxy added successfully."
    else
        echo "Invalid input. Please provide valid values for IP, port, and protocol."
    fi
    echo "Proxy added successfully."
}

function remove_proxy {
    read -p "Enter proxy index to remove (index): " index
    proxy=$(sed -n "${index}p" "$PROXY_LIST")
    if [[ -n "$proxy" ]]; then
        sed -i "${index}d" "$PROXY_LIST"
        echo "Proxy removed successfully."
    else
        echo "Proxy not found in the list."
    fi
}
function process_server {
    echo "Downloading"
    pscp -scp  -pw $PASS -P $PORT $USER@$HOST:/etc/redsocks.conf $CONFIG_FILE
    echo "done"


}
function update_server {
    echo "Uploading"
    pscp -scp -pw "$PASS" -P "$PORT" $CONFIG_FILE "$USER@$HOST:/etc/redsocks.conf"


    plink -ssh -l $USER -pw $PASS -no-antispoof $HOST -P $PORT "service redsocks start"

    plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks restart
    echo "done"

}
function show_current_ip {

   current_ip=$(curl -s ifconfig.me)
   echo "My public IP address is: $current_ip"

}
function manage_redsocks {
    echo "1. Start Service"
    echo "2. Stop Service"
    echo "3. Restart Service"
    echo "4. Get Service"
    echo "5. Update Service"
    echo "e. Quit"
    read -p "Enter your choice: " choice
    case $choice in
        1) plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks start  ;;
        2) plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks stop   ;;
        3) plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks restart ;;
        4) get_redsocks ;;
        5) update_redsocks ;;
        e) echo "Exiting."; break ;;
        *) echo "Invalid choice. Please select again." ;;
    esac
}
function get_redsocks {

    echo "Downloading"
    pscp -scp  -pw $PASS -P $PORT $USER@$HOST:/etc/init.d/redsocks $REDSOCKS
    echo "done"

}
function update_redsocks {

    echo "Uploading"
    pscp -scp  -pw $PASS -P $PORT $REDSOCKS $USER@$HOST:/etc/init.d/redsocks 
    echo "done"
    plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks stop 
    plink  -ssh -l $USER -pw $PASS $HOST -no-antispoof  -P $PORT service redsocks start 

}
echo "Proxy Manager"

while true; do
    echo "0. Show Current IP"
    echo "1. Show Proxies"
    echo "2. Add Proxy"
    echo "3. Remove Proxy"
    echo "4. Set Proxy Configuration"
    echo "5. Manage Service"
    echo "e. Quit"
    read -p "Enter your choice: " choice
    clear

    case $choice in
        0) show_current_ip ;;
        1) show_proxies ;;
        2) add_proxy ;;
        3) remove_proxy ;;
        4) process_set_proxy_config ;;
        5) manage_redsocks ;;
        e) echo "Exiting."; break ;;
        *) echo "Invalid choice. Please select again." ;;
    esac
    
done
