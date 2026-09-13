# kubeadm on bare metal: aries and athena

Runbook for building the cluster directly on the two Ubuntu Server boxes. No Proxmox, no VMs. Run every command yourself over SSH. Sections marked "both" run on both machines, the rest on the named machine only.

Roles:

| Host   | Role          | LAN IP         | Why |
|--------|---------------|----------------|-----|
| athena | control plane | 192.168.5.167  | 16 GB RAM, control plane is light |
| aries  | worker        | 192.168.5.166  | 32 GB RAM, runs the workloads |

Version pinned: Kubernetes 1.36 (supported until June 2027). CNI: Flannel with pod CIDR 10.244.0.0/16.

Both boxes run Ubuntu 26.04.1 LTS (resolute) with containerd 2.2 from the Ubuntu repo. Neither has Tailscale installed on the fresh install, so the Tailscale SAN in step 6 is skipped until that changes. LAN is 192.168.4.0/22.

Paste one block at a time. apt-get install eats the rest of a pasted block from stdin, so lines after it silently never run. That is what happened on the first containerd attempt (Sep 13 2026).

## 0. Preflight (both)

Both nodes need a fixed IP. kubeadm bakes the control plane IP into certificates and the kubelet config, so give both boxes a DHCP reservation on the router or a static netplan entry before you start. Done Sep 13 2026 in the eero app (Settings > Network settings > Reservations & port forwarding), one entry per node pairing its eno1 MAC (`ip link show eno1 | grep ether`) with the IP in the table above.

```bash
lsb_release -a                       # Ubuntu 26.04.1 on both
hostname                             # aries or athena, lowercase
ip -4 addr show                      # note the LAN IP, ignore tailscale0
sudo cat /sys/class/dmi/id/product_uuid   # must differ between the two boxes
```

Put both names in /etc/hosts on both machines so they resolve without DNS:

```bash
sudo tee -a /etc/hosts <<'EOT'
192.168.5.166  aries
192.168.5.167  athena
EOT
```

## 1. Swap off (both)

The kubelet refuses to start with swap on (memory accounting for pods assumes no swap). Ubuntu Server creates /swap.img by default.

```bash
sudo swapoff -a
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab
free -h                              # Swap line should read 0B
```

## 2. Kernel modules and sysctl (both)

overlay is the containerd snapshotter. br_netfilter makes bridged pod traffic visible to iptables so kube-proxy and the CNI can filter and NAT it. ip_forward lets the node route between pods and the outside.

```bash
cat <<'EOT' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOT
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOT' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOT
sudo sysctl --system
```

## 3. containerd (both)

Ubuntu's containerd package is fine. It ships without a config file, so generate the default and change two things: SystemdCgroup so containerd and the kubelet agree on the cgroup driver (Ubuntu boots with cgroup v2 and systemd, a mismatch causes pods to restart randomly), and the pause image so it matches what kubeadm expects.

```bash
sudo apt-get update
sudo apt-get install -y containerd apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
grep -E 'SystemdCgroup|sandbox' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

containerd 2.x names the pause image `sandbox = '...'` under pinned_images (1.x called it sandbox_image). After kubeadm is installed (next step) run `kubeadm config images list` and if its pause tag differs from the grep above, set it and restart containerd:

```bash
sudo sed -i -E "s#(sandbox = ['\"])registry.k8s.io/pause:[0-9.]+#\1registry.k8s.io/pause:<TAG>#" /etc/containerd/config.toml
sudo systemctl restart containerd
```

## 4. kubeadm, kubelet, kubectl (both)

The pkgs.k8s.io repo is per minor version. Holding the packages stops an unattended apt upgrade from bumping the kubelet ahead of the control plane.

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
kubeadm version
```

The kubelet will crash loop until kubeadm init or join gives it a config. That is normal.

## 5. Firewall (both, only if ufw is active)

```bash
sudo ufw status
```

If it says inactive, skip this. Otherwise on athena open 6443/tcp (API), 2379:2380/tcp (etcd), 10250/tcp (kubelet), 10257/tcp and 10259/tcp (controller manager, scheduler). On aries open 10250/tcp and 30000:32767/tcp (NodePorts). On both open 8472/udp (Flannel VXLAN).

## 6. Init the control plane (athena only)

Why each flag:

- pod-network-cidr must match what Flannel expects (10.244.0.0/16 is its default).
- apiserver-advertise-address pins the API server to the LAN NIC. Without it kubeadm may pick tailscale0.
- control-plane-endpoint is what the join command and kubeconfigs point at. Setting it now, even to the same IP, means you can swap in a DNS name or VIP later without re-issuing certs.
- apiserver-cert-extra-sans adds extra names to the API server cert. Only the hostname for now, Tailscale name and IP later if Tailscale gets installed.

```bash
sudo kubeadm config images pull
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.5.167 \
  --control-plane-endpoint=192.168.5.167 \
  --apiserver-cert-extra-sans=athena
```

Tailscale is not installed on the fresh boxes. If it is added later, regenerate the API server cert with the Tailscale name and IP: delete /etc/kubernetes/pki/apiserver.crt and apiserver.key, run `kubeadm init phase certs apiserver --apiserver-cert-extra-sans=athena,<TAILSCALE_HOSTNAME>,<TAILSCALE_IP>`, then restart the kube-apiserver pod.

Save the `kubeadm join ...` line it prints. Then set up kubectl for your user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes                    # athena shows NotReady until the CNI is up
```

## 7. Flannel CNI (athena only)

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl -n kube-flannel get pods -w   # wait for Running
kubectl get nodes                     # athena should go Ready
```

If Flannel picks tailscale0 instead of the LAN NIC (pods on the two nodes cannot reach each other), edit the DaemonSet and add `--iface=<LAN NIC name>` to the kube-flannel container args.

## 8. Join the worker (aries only)

If you lost the join line, on athena run `kubeadm token create --print-join-command` (tokens expire after 24h).

```bash
sudo kubeadm join 192.168.5.167:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## 9. Verify (athena)

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl label node aries node-role.kubernetes.io/worker=
```

Both nodes Ready and every pod in kube-system and kube-flannel Running means the cluster is up.

With only two machines you may want workloads on athena too. The control plane taint blocks that by default:

```bash
kubectl taint nodes athena node-role.kubernetes.io/control-plane:NoSchedule-
```

## 10. kubectl from the laptop (WSL)

Copy /etc/kubernetes/admin.conf from athena to ~/.kube/config in WSL. It points at 192.168.5.167 on the LAN.

## Tear down and retry

If init or join goes wrong, reset and start the step again:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d $HOME/.kube
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```
