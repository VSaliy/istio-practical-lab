# Checkpoints and Backups

Use Hyper-V production checkpoints only when all VMs are shut down.

For Kubernetes state, create etcd snapshots before disruptive changes and test restoration in an isolated environment.
