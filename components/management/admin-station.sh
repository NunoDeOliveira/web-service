## This script automate the conection to admin station

#!/bin/bash

cd ~/projects/web-server-infra/components/management

# Configure Admin Station network
sudo ip addr replace 10.0.0.50/29 dev virbr50

# Configure routes through FW2
sudo ip route replace 10.0.0.32/28 via 10.0.0.49 dev virbr50
sudo ip route replace 10.0.0.0/27 via 10.0.0.49 dev virbr50

# Verify configuration
ip -br addr show virbr50
ip route | grep 10.0.0

# Verify connectivity with FW2
if ping -c 3 -W 2 10.0.0.49; then
    echo "Admin Station network configured successfully."
    #echo "Connecting to FW2..."
    #ssh root@10.0.0.49
    export PS1='\[\e[95m\][admin-station 10.0.0.50]\[\e[0m\] \u@\h:\w\$ '
    cd ~
else
    #echo "ERROR: FW2 is not reachable."
    echo "ERROR: connecting..."
    exit 1
fi
