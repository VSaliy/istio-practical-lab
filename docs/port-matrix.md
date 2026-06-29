# Port Matrix

| Source | Destination | Port/Protocol | Purpose |
|---|---|---|---|
| Worker nodes | control-plane | 6443/TCP | Kubernetes API |
| All nodes | all nodes | 10250/TCP | kubelet |
| Control-plane | etcd | 2379-2380/TCP | etcd client/peer |
| Windows host | ingress gateway LB IP | 80,443/TCP | app ingress |
| Nodes | internet | 443/TCP | package/image download |
