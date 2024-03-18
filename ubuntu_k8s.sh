#!/bin/bash
# set -e
apt update -y
apt upgrade -y
apt install net-tools -y
apt install open-vm-tools -y
apt install iputils-ping -y
apt install traceroute -y
apt install sshpass -y

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
modprobe overlay
modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
sysctl --system
sed -i 's/AllowTcpForwarding no/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding no/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding/AllowTcpForwarding/g' /etc/ssh/sshd_config
apt-cache madison docker-ce | awk '{ print $3 }'

apt-get update -y
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y 
VERSION_STRING=5:24.0.9-1~ubuntu.22.04~jammy
apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
docker version --format '{{.Server.Version}}'
docker version --format '{{.Server.Version}}'
docker info
systemctl status docker
usermod -aG docker cisco

apt install apt-transport-https ca-certificates curl software-properties-common
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
sshpass –p "C1sc0#123" cisco@172.16.250.130

wget https://github.com/rancher/rke/releases/download/v1.5.6/rke_linux-amd64
mv rke_linux-amd64 rke
chmod +x rke
./rke --version




