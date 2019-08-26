#!/bin/bash

echo "download kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl

mv ./kubectl /usr/local/bin/kubectl

echo "source <(kubectl completion bash)" >> ~/.bashrc

echo "download minikube"
curl -LO https://github.com/kubernetes/minikube/releases/download/v1.3.1/minikube-1.3.1.rpm && sudo rpm -ivh minikube-1.3.1.rpm

echo "setting no driver"
minikube config set vm-driver none


systemctl stop firewalld.service; systemctl disable firewalld.service

systemctl enable docker.service

swapoff -a

yum install -y socat

systemctl enable kubelet.service

echo "127.0.0.1 minikube" >> /etc/hosts

useradd k8s

usermod -g docker k8s

echo "k8s ALL=(ALL) ALL " >> /etc/sudoers


echo "minikube start"
sudo minikube start --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers