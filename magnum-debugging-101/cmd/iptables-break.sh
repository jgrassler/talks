iptables -A INPUT \
         -s $(ip addr sh br-public | grep -w inet \
              | awk '{print $2}' | sed 's#/.*##') \
         -p tcp --dport 8004 -j ACCEPT

iptables -A INPUT \
         -s $(neutron net-list | grep floating \
              | awk '{print $7}') \
         -p tcp --dport 8004 \
         -j REJECT --reject-with tcp-reset
