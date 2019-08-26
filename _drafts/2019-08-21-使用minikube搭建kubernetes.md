---
date: 2019-08-19 02:27:00
key: 使用minikube搭建kubernetes
tags: [linux,k8s]
---

使用**virtual box**新建的虚机安装 minikube 来部署k8s 

1. `https://github.com/kubernetes/minikube` 
2. `https://minikube.sigs.k8s.io/docs/start/`(官方文档)
3. `https://k8smeetup.github.io/docs/tasks/tools/install-minikube/`(安装 Minikube)
4. `https://k8smeetup.github.io/docs/getting-started-guides/minikube/`(使用 Minikube)


**需要科学上网**

## 安装 Docker 18.09版本

最新版本的Minikube不支持docker最新版，需要安装docker18.09

[centos7安装docker-ce](/2019/03/12/centos7安装docker-ce.html)

## 安装 kubectl

官方文档:[通过 curl 命令安装 kubectl 可执行文件](https://k8smeetup.github.io/docs/tasks/tools/install-kubectl/#%E9%80%9A%E8%BF%87-curl-%E5%91%BD%E4%BB%A4%E5%AE%89%E8%A3%85-kubectl-%E5%8F%AF%E6%89%A7%E8%A1%8C%E6%96%87%E4%BB%B6)

1. 通过以下命令下载 kubectl 的最新版本：

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
```

若需要下载特定版本的 kubectl，请将上述命令中的 `$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)`部分替换成为需要下载的 kubectl 的具体版本即可。

例如，如果需要下载用于 Linux 的 v1.9.0 版本，需要使用如下命令：

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl
```

2. 修改所下载的 kubectl 二进制文件为可执行模式。

```
chmod +x ./kubectl
```

3. 将 kubectl 可执行文件放置到系统 PATH 目录下。

```
sudo mv ./kubectl /usr/local/bin/kubectl
```

4. linux启用shell自动补全

```
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

## 安装 Minikube

[官方github仓库](https://github.com/kubernetes/minikube/releases)

```
curl -LO https://github.com/kubernetes/minikube/releases/download/v1.3.1/minikube-1.3.1.rpm && sudo rpm -ivh minikube-1.3.1.rpm
``` 

```
sudo minikube config set vm-driver none
```

## 安装前的配置

1. 虚拟最小2核CPU,内存4G.
2. 关闭防火墙 `systemctl stop firewalld.service; systemctl disable firewalld.service`
3. docker开机自启 `systemctl enable docker.service`
4. 禁用交换分区 `swapoff -a`
5. 安装socat依赖 `yum install -y socat`
6. kubelet开机自启 `systemctl enable kubelet.service`
7. 修改hosts文件 `echo "127.0.0.1 minikube" >> /etc/hosts`
8. 新建普通用户 `useradd k8s`
9. 将用户添加到docker组中 `usermod -g docker k8s`
10. 将用户添加到sudo组中 `echo "k8s ALL=(ALL) ALL " >> /etc/sudoers`

## 新建k8s集群

`sudo minikube start --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers`



```
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

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet && systemctl start kubelet
```

sudo minikube start --image-mirror-country=cn