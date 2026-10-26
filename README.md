# Inception of Things

This project is part of 42's outer-circle curriculum, completed by hguo and vgoret.

A 42 school project exploring Kubernetes fundamentals through two
exercises, both run inside Vagrant managed VMs. P1 focuses on bringing
up a small multi-node K3s cluster; P2 builds on that foundation with
three web apps routed through one Ingress.

```
p1/      hguo: 2 node K3s cluster
p2/      hguo: 1 node K3s cluster, 3 apps behind an Ingress
```

## Host prerequisites

VirtualBox and Vagrant are required. On a 42 school machine, sudo is
not available, so Vagrant has to be installed by hand as a portable
build. The commands below install Vagrant 2.4.9 under `~/.local` and
add it to the current user's shell path.

```bash
wget https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_linux_amd64.zip
unzip vagrant_2.4.9_linux_amd64.zip
chmod +x vagrant
./vagrant --appimage-extract
mkdir -p ~/.local
mv squashfs-root ~/.local/vagrant
echo 'export PATH="$HOME/.local/vagrant/usr/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

On Fedora 44, the system may not include `libcrypt.so.1`, which the
bundled Ruby needs. If Vagrant reports a missing `libcrypt.so.1`, the
following commands extract the compatible library locally and add a
small shell wrapper to load it:

```bash
dnf download libxcrypt-compat
mkdir -p ~/libxcrypt-extract
cd ~/libxcrypt-extract
rpm2cpio ../libxcrypt-compat-4.5.2-3.fc44.x86_64.rpm | cpio -idmv
mkdir -p ~/.local/vagrant-libs
cp usr/lib64/libcrypt.so.1 ~/.local/vagrant-libs/
echo 'vagrant() { LD_LIBRARY_PATH="$HOME/.local/vagrant-libs:$LD_LIBRARY_PATH" "$HOME/.local/vagrant/usr/bin/vagrant" "$@"; }' >> ~/.bashrc
source ~/.bashrc
vagrant --version
```

---

## Part 1 (hguo): K3s and Vagrant

Two VMs, `hguoS` as the K3s server at `192.168.56.110` and
`hguoSW` as the K3s agent at `192.168.56.111`, joined into one
cluster. The server hosts the Kubernetes control plane, while the agent
joins it as a worker node. Both VMs use Ubuntu 22.04 and receive their
K3s configuration from the provisioning scripts.

```
p1/
├── Vagrantfile
└── scripts/
    ├── install_k3s_server.sh
    └── install_k3s_agent.sh
```

```bash
cd p1
vagrant up
# Run these checks from the host in separate SSH sessions as needed.
vagrant ssh hguoS
# inside the VM:
sudo systemctl status k3s
kubectl get nodes -o wide

vagrant ssh hguoSW
# inside the VM:
sudo systemctl status k3s-agent

# On the server, both nodes should appear with Ready status.
kubectl get nodes

vagrant halt
vagrant destroy -f
```

## Part 2 (hguo): K3s and three simple applications

One VM, `hguoS` at `192.168.56.110`, runs K3s in single-node server
mode and deploys three nginx apps behind an Ingress. Requests with
the `app1.com` or `app2.com` Host header go to their matching apps;
other requests fall through to `app3`. `app2` runs three replicas to
demonstrate scaling a Deployment, and the Ingress distributes matching
requests across its pods.

The Vagrant provisioning installs K3s, copies the Kubernetes manifests
into the VM, waits for the node to become Ready, and applies the apps
and Ingress automatically.

```
p2/
├── Vagrantfile
├── scripts/
│   ├── install_k3s.sh
│   └── deploy_apps.sh
└── confs/
    ├── app1.yaml
    ├── app2.yaml
    ├── app3.yaml
    └── ingress.yaml
```

```bash
cd p2
vagrant up
vagrant ssh hguoS
# inside the VM:
kubectl get all
curl -H "Host: app1.com" 192.168.56.110
curl -H "Host: app2.com" 192.168.56.110
curl 192.168.56.110

kubectl get ingress
kubectl describe ingress

# Check the workloads and routing resources if a request does not respond.
kubectl get deployments,pods,services,ingress

vagrant halt
vagrant destroy -f
```

