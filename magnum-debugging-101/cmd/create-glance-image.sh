glance image-create --name openstack-magnum-k8s-image \
                    --visibility public \
                    --disk-format qcow2 \
                    --os-distro opensuse \
                    --container-format bare\
                    --file /srv/tftpboot/files/openstack-magnum-k8s-image/openstack-magnum-k8s-image.x86_64.qcow2
