nested=$(openstack stack resource list -n 5 $stack \
                | grep CREATE_FAILED \
                | grep OS::Heat::WaitCondition \
                | awk '{print $11}')
export nested
