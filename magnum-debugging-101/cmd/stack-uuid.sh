stack=$(magnum cluster-show k8s_cluster \
        | grep -w stack_id \
        | awk '{print $4}')
export stack
