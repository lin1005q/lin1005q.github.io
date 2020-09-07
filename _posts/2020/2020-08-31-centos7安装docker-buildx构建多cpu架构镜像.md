---
date: 2020-08-31 17:27:00 +0800
tags: [centos]
---

## 升级内核版本

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
# 查询目前可升级的内核版本
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
# 安装kernel-ml 最新版
yum --enablerepo=elrepo-kernel install kernel-ml -y
# 查询所有启动候选项
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
# 设置grub引导默认启动项
grub2-set-default 0
# 重启
reboot
# 检测内核版本
uname -a
```

## 卸载旧内核

```bash
[root@localhost ~]# rpm -qa | grep kernel
kernel-3.10.0-327.22.2.el7.x86_64
kernel-devel-3.10.0-327.22.2.el7.x86_64
kernel-tools-libs-3.10.0-327.28.2.el7.x86_64
kernel-headers-3.10.0-327.28.2.el7.x86_64
kernel-3.10.0-327.28.2.el7.x86_64
kernel-devel-3.10.0-327.13.1.el7.x86_64
php-symfony-http-kernel-2.8.7-1.el7.noarch
kernel-tools-3.10.0-327.28.2.el7.x86_64
kernel-devel-3.10.0-327.28.2.el7.x86_64
kernel-devel-3.10.0-327.18.2.el7.x86_64

[root@localhost ~]# yum remove kernel-3.10.0*
[root@localhost ~]# reboot
```

## 安装qemu

```bash
# 安装epel yum库
wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum install qemu -y
```

## 安装docker

[centos7安装docker-ce](/2019/03/12/centos7安装docker-ce)

```bash
# 最新版
curl -sSl https://qiao.dev/bash/install_docker_latest_centos.sh | sh
# k8s最新支持版本 18.09.8
curl -sSl https://qiao.dev/bash/install_docker_18.09.8_centos.sh | sh
```

## 启动docker buildx

```bash
# 添加server端开启试验功能的配置  
cat << EOF > /etc/docker/daemon.json
{
  "experimental":true
}
EOF
# 添加client端开启试验功能的配置 
echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> ~/.bashrc
source ~/.bashrc
# restart docker daemon
systemctl restart docker
# 验证开启的试验功能
docker version | grep Experimental

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use --name=mybuilder
docker buildx inspect --bootstrap
# 查询 builder list
docker buildx ls
```

## 添加私有仓库的ssl证书到buildx容器内

```bash
BUILDER=$(docker ps | grep buildkitd | cut -f1 -d' ')
docker cp /etc/docker/certs.d/harbor.offline/harbor.offline.crt $BUILDER:/usr/local/share/ca-certificates/
docker exec $BUILDER sh -c "cat /usr/local/share/ca-certificates/harbor.offline.crt >> /etc/ssl/certs/ca-certificates.crt"
docker restart $BUILDER
```

## 构建镜像

```bash
# 新建Dockerfile
mkdir buildx  && cd buildx
cat << EOF > Dockerfile
FROM adoptopenjdk:14.0.2_8-jre-hotspot
RUN echo "111"
EOF

docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t wang1010q/test-multiarch --push .
```

> [使用 docker buildx 构建多 CPU 架构镜像](https://developer.aliyun.com/article/761569)