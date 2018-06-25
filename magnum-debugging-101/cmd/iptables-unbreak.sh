iptables -D INPUT \
         -s $(neutron net-list | grep floating \
              | awk '{print $7}') \
         -p tcp --dport 8004 \
         -j REJECT --reject-with tcp-reset
