cat /etc/hosts
192.168.99.11 node1
192.168.99.12 node2


systemctl stop firewalld
systemctl disable firewalld

setenforce 0

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# echo -e "net.bridge.bridge-nf-call-ip6tables = 1 \nnet.bridge.bridge-nf-call-iptables = 1 \nnet.ipv4.ip_forward = 1" > /etc/sysctl.d/k8s.conf

modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

yum install ipvsadm -y

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# yum list docker-ce.x86_64  --showduplicates |sort -r

sudo yum remove docker docker-client docker-client-latest \
                  docker-common docker-latest docker-latest-logrotate \
                  docker-logrotate docker-engine \
                  docker-ce docker-ce-cli containerd.io -y

rm -rf /var/lib/docker

yum makecache fast
yum install -y --setopt=obsoletes=0 docker-ce-18.09.9-3.el7 
systemctl start docker
systemctl enable docker

iptables -P FORWARD ACCEPT
iptables -nvL
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl restart docker
docker info | grep Cgroup
#Cgroup Driver: systemd

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum makecache fast

yum remove kubelet kubeadm
yum install kubeadm-1.15.6 kubelet-1.15.6 kubectl-1.15.6 -y

swapoff -a

echo "vm.swappiness=0" >> /etc/sysctl.d/k8s.conf

systemctl enable kubelet.service

# kubeadm config print init-defaults


cat > kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.30.153
  bindPort: 6443
nodeRegistration:
  taints:
  - effect: PreferNoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.15.6
networking:
  podSubnet: 10.244.0.0/16
EOF

# kubeadm config images list

# 反斜杠 避免将$变量丢失
cat > image.sh <<EOF
images=(  # 下面的镜像应该去除"k8s.gcr.io/"的前缀，版本换成上面获取到的版本
    kube-apiserver:v1.15.6
    kube-controller-manager:v1.15.6
    kube-scheduler:v1.15.6
    kube-proxy:v1.15.6
    pause:3.1
    etcd:3.3.10
    coredns:1.3.1
    kubernetes-dashboard-amd64:v1.10.1
    
)

for imageName in \${images[@]} ; do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/\$imageName
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/\$imageName k8s.gcr.io/\$imageName
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/\$imageName
done
EOF

chmod +x image.sh
bash image.sh

# kubeadm config images pull
kubeadm init --config kubeadm.yaml


# kubeadm reset
# ifconfig cni0 down
# ip link delete cni0
# ifconfig flannel.1 down
# ip link delete flannel.1
# rm -rf /var/lib/cni/