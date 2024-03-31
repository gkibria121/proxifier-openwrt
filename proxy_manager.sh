#!/bin/bash

PROXY_LIST="proxy_list.txt"
CONFIG_FILE="redsocks.conf"

# Function to set proxy configuration in redsocks.conf
function set_proxy_config {
    local ip=$1
    local port=$2
    local type=$3
    local username=$4
    local password=$5
    local config_file=$6

    # Update the redsocks configuration block in the config file

    sed -i "s|^\s*ip\s*.*$|        ip = $ip;|" "$config_file"
    sed -i "s|^\s*port\s*.*$|        port = $port;|" "$config_file"
    sed -i "s|^\s*type\s*.*$|        type = $type;|" "$config_file"
    sed -i "s|^\s*login\s*.*$|        login = \"$username\";|" "$config_file"
    sed -i "s|^\s*password\s*.*$|        password = \"$password\";|" "$config_file"
}

function process_set_proxy_config {
    read -p "Enter proxy index to set configuration: " index
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
    echo "$ip:$port:$username:$password:$protocol" >> "$PROXY_LIST"
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

echo "Proxy Manager"

while true; do
    echo "1. Show Proxies"
    echo "2. Add Proxy"
    echo "3. Remove Proxy"
    echo "4. Set Proxy Configuration"
    echo "5. Quit"
    read -p "Enter your choice: " choice

    case $choice in
        1) show_proxies ;;
        2) add_proxy ;;
        3) remove_proxy ;;
        4) process_set_proxy_config ;;
        5) echo "Exiting."; break ;;
        *) echo "Invalid choice. Please select again." ;;
    esac
done
