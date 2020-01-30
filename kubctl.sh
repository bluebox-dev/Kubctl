#!/bin/bash
# Color-txt
Red="\033[1;31m" 
Green="\033[1;32m"
Blue="\033[1;34m"
Nocolor="\033[0m"

# CommandLine
echo -e "Install ${Blue}Kubernetes Basic${Nocolor} CentOS 7"
read -p 'Do you want to continue? [Y/n] ' varinstall
if [[ "$varinstall" == "y" ]]
then
# Basic.kubernetes
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

## Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

## Install kubernetes
yum install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

## Comment out swap line in fstab so that it remains disabled after reboot
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

## Kernel sysctl configuration file
# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

## Svc start all
systemctl start docker && systemctl enable docker
systemctl start kubelet && systemctl enable kubelet

# Master Create
echo -e "Role is ${Red}Master Kubernetes${Nocolor}"
read -p 'Do you want to continue? [Y/n] ' varmaster
    if [[ "$varmaster" == "y" ]]
    then
        read -p '--apiserver-advertise-address=' varipmaster
        read -p '--pod-network-cidr=' variplocal
        ## Firewalls Master
        firewall-cmd --permanent --add-port=6443/tcp
        firewall-cmd --permanent --add-port=2379-2380/tcp
        firewall-cmd --permanent --add-port=10250/tcp
        firewall-cmd --permanent --add-port=10251/tcp
        firewall-cmd --permanent --add-port=10252/tcp
        firewall-cmd --permanent --add-port=10255/tcp
        firewall-cmd --reload
        ## Role Master
        kubeadm init --apiserver-advertise-address=$varipmaster --pod-network-cidr=$variplocal
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        # kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        echo -e "${Green}Complete Master Kubernetes${Nocolor}"
    else
        #Firewalls Worker
        sudo firewall-cmd --permanent --add-port=10251/tcp
        sudo firewall-cmd --permanent --add-port=10255/tcp
        firewall-cmd --reload
        read -p 'Kubernetes-joincommand:' varjoincommand
        $varjoincommand
        echo -e "${Green}Complete Worker Kubernetes${Nocolor}"
    fi
else
    echo 
fi