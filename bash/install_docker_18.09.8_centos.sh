#!/bin/bash

# Uninstall old versions
sudo yum remove docker docker-client docker-client-latest \
                  docker-common docker-latest docker-latest-logrotate \
                  docker-logrotate docker-engine \
                  docker-ce docker-ce-cli containerd.io -y

rm -rf /var/lib/docker

# Install using the repository
# Install required packages. 
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 -y

# Use the following command to set up the stable repository.
# docker 官方库
# sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 阿里镜像库
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# Install the latest version of Docker Engine - Community and containerd, or go to the next step to install a specific version:
# sudo yum install docker-ce docker-ce-cli containerd.io -y

# yum list docker-ce --showduplicates | sort -r

# docker-ce.x86_64  3:18.09.1-3.el7                     docker-ce-stable
# docker-ce.x86_64  3:18.09.0-3.el7                     docker-ce-stable
# docker-ce.x86_64  18.06.1.ce-3.el7                    docker-ce-stable
# docker-ce.x86_64  18.06.0.ce-3.el7                    docker-ce-stable

# sudo yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io
sudo yum install docker-ce-18.09.8-3.el7 docker-ce-cli-18.09.8-3.el7 containerd.io -y

# Start Docker.
sudo systemctl start docker

echo "install docker 18.09.8 success"

echo "you could docker run hello-world to test"

# sudo docker run hello-world

# adding your user to the “docker” group with something like:
# sudo usermod -aG docker your-user

# Uninstall docker
# sudo yum remove docker-ce
# sudo rm -rf /var/lib/docker