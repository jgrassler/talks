magnum cluster-template-create \
                      \
  --name k8s_template \
  --image-id openstack-magnum-k8s-image \
  --keypair-id default \
  --external-network-id floating \
  --dns-nameserver 8.8.8.8 \
  --flavor-id m1.magnum \
  --master-flavor-id m1.magnum \
  --docker-volume-size 5 \
  --network-driver flannel \
  --coe kubernetes \
  --tls-disabled
