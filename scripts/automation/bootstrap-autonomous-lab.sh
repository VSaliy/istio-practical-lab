#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '\n[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

run() {
  log "$*"
  "$@"
}

REPO_URL="${REPO_URL:-https://github.com/VSaliy/istio-practical-lab.git}"
REPO_BRANCH="${REPO_BRANCH:-feature/excercises}"
LAB_DIR="${LAB_DIR:-$HOME/istio-practical-lab}"
SSH_USER="${SSH_USER:-$(id -un)}"
CONTROL_HOST="${CONTROL_HOST:-172.22.0.10}"
WORKER_HOSTS="${WORKER_HOSTS:-172.22.0.11 172.22.0.12}"
INGRESS_HOST="${INGRESS_HOST:-172.22.0.240}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=10 -o ServerAliveCountMax=12)

log "Installing bootstrap prerequisites on control node"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ansible git openssh-client python3-apt curl jq

if [[ -d "${LAB_DIR}/.git" ]]; then
  log "Updating repository ${LAB_DIR}"
  git -C "${LAB_DIR}" fetch origin "${REPO_BRANCH}"
else
  log "Cloning ${REPO_URL} to ${LAB_DIR}"
  git clone "${REPO_URL}" "${LAB_DIR}"
fi

cd "${LAB_DIR}"
run git checkout "${REPO_BRANCH}"
run git pull --ff-only origin "${REPO_BRANCH}"

log "Verifying SSH reachability from control node to all lab nodes"
for host in ${CONTROL_HOST} ${WORKER_HOSTS}; do
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${host}" 'hostname && true'
done

log "Preparing all Kubernetes nodes with Ansible"
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory.ini \
  -u "${SSH_USER}" \
  --ssh-common-args='-o StrictHostKeyChecking=accept-new' \
  ansible/site.yml

log "Verifying Ansible node preparation"
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i ansible/inventory.ini \
  -u "${SSH_USER}" \
  --ssh-common-args='-o StrictHostKeyChecking=accept-new' \
  ansible/verify.yml

if [[ -f /etc/kubernetes/admin.conf ]]; then
  log "Control plane already initialized; reusing existing kubeconfig"
  mkdir -p "$HOME/.kube"
  sudo cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
  sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
else
  log "Initializing Kubernetes control plane"
  bash scripts/install/initialize-control-plane.sh
fi

log "Installing Calico"
bash scripts/install/install-calico.sh

JOIN_CMD="$(bash scripts/install/generate-worker-join-command.sh)"
log "Joining worker nodes"
for host in ${WORKER_HOSTS}; do
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${host}" \
    "if [ -f /etc/kubernetes/kubelet.conf ]; then echo '${host} already joined'; else sudo ${JOIN_CMD}; fi"
done

log "Waiting for all Kubernetes nodes to become Ready"
kubectl wait --for=condition=Ready node --all --timeout=600s
kubectl get nodes -o wide

log "Installing Metrics Server"
bash scripts/install/install-metrics-server.sh

log "Installing MetalLB"
bash scripts/install/install-metallb.sh

log "Installing Istio"
bash scripts/install/install-istio.sh

log "Deploying Bookinfo"
bash scripts/install/deploy-bookinfo.sh
kubectl wait --for=condition=Ready pod --all -n bookinfo --timeout=600s

log "Installing Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace argocd istio-injection=disabled --overwrite
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

log "Applying GitOps Bookinfo routing application"
kubectl apply -f exercises/21-gitops/manifests/argocd-bookinfo-application.yaml
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/bookinfo-routing --timeout=300s || true
kubectl get application bookinfo-routing -n argocd

log "Final validation"
kubectl get nodes -o wide
kubectl get pods -A
istioctl analyze -n bookinfo
curl -fsSI "http://${INGRESS_HOST}/productpage"
bash scripts/smoke/run-smoke-tests.sh

log "Autonomous lab bootstrap completed"
