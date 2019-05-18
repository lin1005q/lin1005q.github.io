---
title: jdk安装
key: jdk安装
tags: [java基础,eap,shell]
date: 2018-01-13
sidebar:
  nav: eap-zh
---

## JDK下载

```bash

## openjdk11
wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz

## openjdk8 GPLv2的下载地址
wget https://download.java.net/openjdk/jdk8u40/ri/openjdk-8u40-b25-linux-x64-10_feb_2015.tar.gz

## jdk6 oracle和openjdk已经不提供下载 

tar -zxvf openjdk-8u40-b25-linux-x64-10_feb_2015.tar.gz
mv java-se-8u40-ri /usr/local/
chown -R root:root java-se-8u40-ri
echo "export JAVA_HOME=/usr/local/java-se-8u40-ri" >> /etc/profile
echo "export PATH=$PATH:$JAVA_HOME/bin" >> /etc/profile
source /etc/profile
java -version

```

```bash
export JAVA_HOME=/root/jdk1.8.0_121
export PATH=$JAVA_HOME/bin:$PATH 
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar 
```
