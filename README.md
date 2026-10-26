# Inception of Things

This project is part of 42's outer-circle curriculum, completed by hguo and vgoret.

A 42 school project exploring Kubernetes fundamentals through two
exercises. Vagrant manages the virtual machines for both parts. P1 creates
a two-node K3s cluster; P2 creates a single-node K3s cluster and routes
traffic to three web apps through one Ingress.

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

This part creates two VMs and joins them to one cluster: `hguoS` is the
K3s server at `192.168.56.110`, and `hguoSW` is the K3s agent at
`192.168.56.111`. The server runs the Kubernetes control plane; the agent
joins it as a worker node. Both VMs use Ubuntu 22.04 and are configured by
their respective provisioning scripts.

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
```

Run the following from the host to enter each VM. The service checks run
inside the VM named in the preceding SSH command; run `exit` before opening
the other VM's SSH session.

```bash
vagrant ssh hguoS
sudo systemctl status k3s
kubectl get nodes -o wide
exit

vagrant ssh hguoSW
sudo systemctl status k3s-agent
exit
```

On `hguoS`, `kubectl get nodes` should list both nodes with `Ready` status:

```bash
vagrant ssh hguoS
kubectl get nodes
exit
```

Run Vagrant lifecycle commands from the host, in `p1/` (not inside a VM):

```bash
vagrant halt
```

To remove the VMs and their data, run this from the host in `p1/`:

```bash
vagrant destroy -f
```

## Part 2 (hguo): K3s and three simple applications

One VM, `hguoS` at `192.168.56.110`, runs K3s in server mode and hosts
all three nginx apps. An Ingress routes requests with the `app1.com` Host
header to app1 and `app2.com` to app2; requests with any other Host header
go to app3. The app2 Deployment has three replicas, and its Service routes
traffic to those pods.

During `vagrant up`, Vagrant installs K3s, copies the Kubernetes manifest
files from `p2/confs` into the VM, waits for the node to become `Ready`,
then applies the manifests to create the apps and Ingress.

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
```

Enter the VM and check the resources and routes. The `curl` commands set
the HTTP `Host` header so the Ingress can choose the matching app; a request
without an explicit Host header is routed to app3.

```bash
vagrant ssh hguoS
kubectl get all
curl -H "Host: app1.com" 192.168.56.110
curl -H "Host: app2.com" 192.168.56.110
curl 192.168.56.110

kubectl get ingress
kubectl describe ingress

# Inspect these resources if a request does not return the expected page.
kubectl get deployments,pods,services,ingress
exit
```

Run Vagrant lifecycle commands from the host, in `p2/`:

```bash
vagrant halt
```

To remove the VM and its data, run this from the host in `p2/`:

```bash
vagrant destroy -f
```

