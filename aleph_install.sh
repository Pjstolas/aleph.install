#!/bin/bash

# Exit on any error
set -e

# Function to check if the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi
}

# Function to update and upgrade the OS
update_upgrade() {
    echo "Updating and upgrading the system..."
    apt update
    apt upgrade -y
}

# Function to disable os logs 
rsyslog_disable() {
    systemctl disable rsyslog.service
}

# Function to install Docker and run vm-connector
install_docker_vmconnector() {
    echo "Installing Docker and running vm-connector..."
    apt install -y docker.io
    docker run -d -p 127.0.0.1:4021:4021/tcp --restart=always --name vm-connector alephim/vm-connector:alpha
}

# Function to install aleph-vm
install_aleph_vm() {
    echo "Installing aleph-vm..."
    wget -P /opt https://github.com/aleph-im/aleph-vm/releases/download/1.3.0/aleph-vm.ubuntu-22.04.deb
    apt install -y /opt/aleph-vm.ubuntu-22.04.deb
}

# Function to install Caddy
install_caddy() {
    echo "Installing Caddy..."
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update
    apt install -y caddy
}

# Function to configure Caddy and aleph-vm
configure_caddy_aleph() {
    echo "Configuring Caddy and aleph-vm..."
    cat >/etc/caddy/Caddyfile <<EOL
{
    https_port 443
}


<--------->:443 {
    tls {
       on_demand
    }
    
    reverse_proxy http://127.0.0.1:4020 {
        # Forward Host header to the backend
        header_up Host {host}
    }
}
EOL

    cat >/etc/aleph-vm/supervisor.env <<EOL
ALEPH_VM_PRINT_SYSTEM_LOGS=True
#ALEPH_VM_USE_JAILER=True
ALEPH_VM_DOMAIN_NAME=
ALEPH_VM_NETWORK_INTERFACE=ens18
ALEPH_VM_DNS_RESOLUTION=resolvectl
ALEPH_VM_IPV6_FORWARDING_ENABLED=False
#ALEPH_VM_IPV6_ADDRESS_POOL="/64"
ALEPH_VM_PAYMENT_RECEIVER_ADDRESS=""
EOL
}

# Function to install sshd
install_openssh() {
    echo "Installing oepnssh..."
    sudo apt install openssh-server -y
}

# Main execution
main() {
    check_sudo
    update_upgrade
    rsyslog_disable
    install_docker_vmconnector
    install_aleph_vm
    install_caddy
    configure_caddy_aleph
#    install_openssh
    echo "Setup completed successfully!"
    echo "To finish installation use NANO to manually change '/etc/aleph-vm/supervisor.env' file and '/etc/caddy/Caddyfile' with your domain and the network interface (ip a)"
}


# Run the main function
main
