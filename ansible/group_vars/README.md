# group_vars

`all.yml` contains the pinned versions used by the optional Ansible node
preparation path.

Keep these values aligned with the repository root `versions.env` file:

- `kubernetes_version`
- `containerd_version`
- `crictl_version`

The Ansible layer intentionally duplicates these values because Ansible does not
read shell `.env` files natively. Treat `versions.env` as the source of truth and
update `group_vars/all.yml` when the lab version matrix changes.
