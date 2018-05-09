openstack stack resource list -n 5 a4fcbd98-b7d0-4f74-8d88-51bbd5d229d4 \
  | grep -w WaitCondition \
  | grep CREATE_FAILED
  | awk '{print $2}'
