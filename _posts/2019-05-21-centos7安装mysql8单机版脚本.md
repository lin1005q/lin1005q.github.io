---
title: centos7安装mysql8单机版脚本
key: centos7安装mysql8单机版脚本
tags: [shell，sql]
---

# mysql安装

## 准备

```bash
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz
rm -f /etc/my.cnf
rm -rf /etc/mysql
yum install libaio
groupadd mysql
# -r 系统用户 -g 指定组名 -s 新用户的登录shell
useradd -r -g mysql -s /bin/false mysql
cd /usr/local
tar xvf /path/to/mysql-VERSION-OS.tar.xz
ln -s full-path-to-mysql-VERSION-OS mysql
cd mysql

# 添加到环境变量，便于后续操作
echo "export PATH=/usr/local/mysql/bin:$PATH" >> /etc/profile
source /etc/profile

```

## 添加配置文件

新增文件`/etc/my.cnf`,内容如下:

```conf
[mysqld]
datadir=/home/mysql/mysqldata
socket=/home/mysql/mysqldata/mysql.sock
port=9000
# sqlYog连接数据库失败，修改密码加密方式为native
default_authentication_plugin=mysql_native_password
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

[mysqld_safe]
log-error=/home/mysql/mysqllog/mariadb.log
pid-file=/home/mysql/mysqldata/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
```

自定义修改datadir、socket、port、log等的配置 将其修改为mysql用户有权限的目录，这里直接设置为mysql用户的home目录下。

```bash
vi /etc/my.cnf
mkdir /etc/my.cnf.d
mkdir /home/mysql
mkdir /home/mysql/mysqldata
mkdir /home/mysql/mysqllog
echo "" > /home/mysql/mysqllog/mariadb.log

chown -R mysql:mysql /home/mysql
chmod -R 750 /home/mysql

```

## 初始化

**defaults-file必须要在第一个位置**

```bash
# 这一步会生成默认的/etc/my.cnf文件 控制台会弹出root密码
mysqld --defaults-file=/etc/my.cnf --initialize --user=mysql
mysql_ssl_rsa_setup
```

这一步执行完控制台会显示新的root密码。复制保存。
这一步不能多次执行。多次执行会报错，提示data目录已经存在，需要删除再初始化。

# mysql使用

## 添加软链接

将修改后的mysql的socket文件软链接到`/tmp/mysql.socket`,这是因为mysql8的命令行工具默认使用socket文件去进行连接数据库，当然可以在my.cnf文件中直接将socket修改为`/tmp/mysql.socket`

`ln -s /home/mysql/mysqldata/mysql.sock /tmp/mysql.sock`

## 启动

`mysqld_safe --user=mysql &`

## mysql使用前的配置

1. `mysql -u root -p `连接数据库
2. 输入密码（刚才复制保存的那个）
3. 执行任何操作，mysql会提示你修改密码
4. `alter user 'root'@'localhost' identified by '密码';`

## 关闭

`mysqladmin -u root -p shutdown`之后再输入密码

## 添加用户

```sql
CREATE USER 'test'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'test'@'%' WITH GRANT OPTION;
```

## 关闭防火墙

```bash
systemctl stop firewalld
systemctl disable firewalld
```

## 修改密码加密方式

`ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxxx';`

或者直接在my.cnf文件中指定`default_authentication_plugin=mysql_native_password`。