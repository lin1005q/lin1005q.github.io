#!/bin/bash
# k8s single master sh

# check user
[[ $UID -ne 0 ]] && { echo "Must run in root user !";exit; }
# 此处校验cpu核心数
# cat /proc/cpuinfo | grep processor | wc -l

version=${version:=1.15.6}
#镜像仓库
image_url=${image_url:=registry.aliyuncs.com/google_containers}
#Pod子网
pod_subnet=${pod_subnet:=10.100.0.0/16}
#Service子网
service_subnet=${service_subnet:=10.96.0.0/16}
#cluster Name
clusterName=${clusterName:=kubernetes}

docker_version=${docker_version:=18.09.9-3.el7}

function info_log (){
  echo -e "\033[32m[INFO]$1\033[0m"
}

function debug_log (){
  echo -e "[DEBUG]$1"
}

function install_kube(){
info_log "安装kubeadm kubectl kubelet v${version}"

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

yum makecache fast &>/dev/null
debug_log "yum remove kubelet* kubeadm* kubectl* -y"
yum remove kubelet* kubeadm* kubectl* -y &>/dev/null
debug_log "yum install kubeadm-${version} kubelet-${version} kubectl-${version} -y &>/dev/null"
yum install kubeadm-${version} kubelet-${version} kubectl-${version} -y &>/dev/null
systemctl daemon-reload
systemctl enable kubelet
info_log "安装kubeadm kubectl kubelet v${version} success\n"
}

function install_docker(){
info_log "安装docker v${docker_version}"
yum install -y yum-utils device-mapper-persistent-data lvm2 &>/dev/null
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo &>/dev/null

# yum list docker-ce.x86_64  --showduplicates |sort -r
debug_log "yum remove old docker"
sudo yum remove docker docker-client docker-client-latest \
                  docker-common docker-latest docker-latest-logrotate \
                  docker-logrotate docker-engine \
                  docker-ce docker-ce-cli containerd.io -y &>/dev/null

rm -rf /var/lib/docker 
yum makecache fast &>/dev/null
debug_log "yum install docker v${docker_version}"
# yum list docker-ce.x86_64  --showduplicates |sort -r
yum install -y --setopt=obsoletes=0 docker-ce-${docker_version} &>/dev/null
systemctl start docker
systemctl enable docker
debug_log "setting native.cgroupdriver=systemd"
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "storage-driver": "overlay2",
  "storage-opts": ["overlay2.override_kernel_check=true"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
systemctl daemon-reload
systemctl restart docker
info_log "安装docker v${docker_version} success\n"

docker info &>/dev/null
[ $? -eq 0 ] || { echo "install docker error ";exit; }
}

function set_network(){
info_log "网络设置"
debug_log "关闭防火墙 firewalld ufw iptables"
systemctl stop firewalld &>/dev/null
systemctl disable firewalld &>/dev/null
[[ -f /etc/init.d/ufw ]] && { ufw disable;}
[[ -f /etc/init.d/iptables ]] && { /etc/init.d/iptables stop; }

debug_log "关闭SELINUX"
setenforce  0 &>/dev/null
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config

debug_log "关闭swap"
swapoff -a 
sed -i 's/.*swap.*/#&/' /etc/fstab &>/dev/null

debug_log "内核设置"
cat <<EOF > /etc/sysctl.d/k8s.conf
# 修复ipvs模式下长连接timeout问题 小于900即可
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
# 要求iptables不对bridge的数据进行处理
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.netfilter.nf_conntrack_max = 2310720
fs.inotify.max_user_watches=89100
#fs.may_detach_mounts = 1
fs.file-max = 52706963
fs.nr_open = 52706963
vm.swappiness = 0
vm.overcommit_memory=1
vm.panic_on_oom=0
EOF
sysctl -p /etc/sysctl.d/k8s.conf &>/dev/null

debug_log "开启ipvs"
yum install ipvsadm -y &>/dev/null
mkdir -p /etc/sysconfig/modules
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules &>/dev/null
# lsmod | grep -e ip_vs -e nf_conntrack_ipv4

}


function set_time(){
timedatectl set-timezone Asia/Shanghai
}

function reset_kube(){
kubeadm reset -f &>/dev/null
systemctl stop kubelet
ifconfig flannel.1 down &>/dev/null;ip link del flannel.1 &>/dev/null
ifconfig cni0 down &>/dev/null;ip link del cni0 &>/dev/null
ifconfig flannel.1 tunl0 &>/dev/null;ip link del tunl0 &>/dev/null
ip link del kube-ipvs0 &>/dev/null
ip link del dummy0 &>/dev/null
ip link del tunl0@NONE &>/dev/null
>/tmp/kubeadm-init.log
rm -rf /var/lib/cni/
}

modprobe br_netfilter

# kubeadm config print init-defaults

install_docker
install_kube
set_network
set_time


cat > kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 0.0.0.0
  bindPort: 6443
nodeRegistration:
  taints:
  - effect: PreferNoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v${version}
imageRepository: ${image_url}
clusterName: ${clusterName}
networking:
  serviceSubnet: "${service_subnet}"
  podSubnet: "${pod_subnet}"
  dnsDomain: "cluster.local"
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
# bash image.sh

# kubeadm config images pull
kubeadm init --config kubeadm.yaml

#kubectl认证
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#让master也运行pod
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/master=:PreferNoSchedule

info_log "部署flannel网络"

#curl -sLo  kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
curl -sLo kube-flannel.yml http://elven.vip/ks/k8s/yml/kube-flannel_v0.11.0.yml.sh
#修改子网
sed -i "s#10.244.0.0/16#${pod_subnet}#" kube-flannel.yml
#修改镜像源
sed -i 's@quay.io/coreos/flannel:v0.11.0-amd64@alivv/flannel:v0.11.0-amd64@' kube-flannel.yml
#部署
kubectl apply -f kube-flannel.yml

info_log "部署dashboard"
#https://github.com/kubernetes/dashboard/releases
#wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
curl -so kubernetes-dashboard.yaml http://elven.vip/ks/k8s/yml/kubernetes-dashboard_v1.10.1.yml.sh
#修改镜像源地址
sed -i "s@k8s.gcr.io@${image_url}@g" kubernetes-dashboard.yaml
#使用 NodePort 模式映射 30000 至 k8s 所有宿主机上
sed -i '/targetPort: 8443/a\ \ \ \ \ \ nodePort: 30000\n\ \ type: NodePort' kubernetes-dashboard.yaml
#部署 Dashboard
kubectl apply -f kubernetes-dashboard.yaml


#创建访问用户和授权
#把serviceaccount绑定在clusteradmin，授权serviceaccount用户具有整个集群的访问管理权限
kubectl create serviceaccount  dashboard-admin -n kube-system
kubectl create clusterrolebinding  dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
#查看访问Dashboard的认证令牌
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}') |awk '/token:/{print$2}' >$HOME/k8s.token.dashboard.txt

##############################
echo  
echo  
echo -e "\033[32mdashboard登录令牌如下:\033[0m"
echo  
cat $HOME/k8s.token.dashboard.txt
echo  
echo '登录dashboard，输入令牌token'
echo '若提示 不安全的连接, 高级->添加例外'
echo -e "\033[32mdashboard登录地址 https://本机IP:30000 \033[0m"
Local_IP=$(kubectl -n kube-system get cm kubeadm-config -oyaml |awk '/advertiseAddress/{print $NF}')
echo "  https://${Local_IP}:30000"
echo  
if [ -n "${Node_VIP}" ];then
echo  
echo -e "\033[32m添加Master节点代码保存到 $HOME/k8s.add.master.txt\033[0m" 
echo -e "\033[32m添加Master节点代码如下:\033[0m" 
echo  
cat $HOME/k8s.add.master.txt
echo 
fi
echo -e "\033[32m添加node节点代码保存到 $HOME/k8s.add.node.txt\033[0m" 
echo -e "\033[32m添加k8s node节点代码如下:\033[0m" 
echo  
cat $HOME/k8s.add.node.txt
echo  
echo -e "\033[32m查看K8S状态  kubectl get cs\033[0m" 
kubectl get cs
echo
echo -e "\033[32m查看Node     kubectl get nodes\033[0m" 
kubectl get nodes
echo  
echo -e "\033[32mk8s v${Ver} 安装完成，相关Pod正在启动……\033[0m" 

#pod check
# for((i=1;i<100;i++));do
# kubectl get pod -A &>/tmp/pod.log
# if [ $(grep 'Running' /tmp/pod.log |wc -l) -ge 9 ];then
#     End_time=$(date +%s)
#     Cost_time=$(($End_time-$Start_time))
#     echo "RunTime $(($Cost_time/60))m $(($Cost_time%60))s"
#     i=999
# else
#     echo -n "->"
#     sleep 3
# fi
# done

exit 0