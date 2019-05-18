---
title: 
key: weblogic添加oracle-rac数据源
tags: [web服务器]
---

## Before

* WebLogic Server Version **12.1.3.0.0**
* oracle 节点1 192.168.1.1 1521 testdb1
* oracle 节点2 192.168.1.2 1521 testdb2
* service name testdb
* username name
* password pwd

## Action

### 打开weblogic console,输入用户名,密码.登录
### 点击数据源
![点击数据源](/images/datasourceJNDI/2018-05-07_125437.jpg) 

### 点击一般数据源
![点击数据源](/images/datasourceJNDI/2018-05-07_130250.jpg) 

### 输入JNDI 名称
![点击数据源](/images/datasourceJNDI/2018-05-07_130643.jpg) 
#### 下一页
![点击数据源](/images/datasourceJNDI/2018-05-07_131008.jpg) 
#### 下一页
![点击数据源](/images/datasourceJNDI/2018-05-07_131128.jpg) 
### 以节点1的连接配置进行测试
![点击数据源](/images/datasourceJNDI/2018-05-07_131349.jpg) 
#### 下一页  
**oracle.jdbc.driver.OracleDriver**  复制使用
![点击数据源](/images/datasourceJNDI/2018-05-07_133146.jpg) 
![点击数据源](/images/datasourceJNDI/2018-05-07_133158.jpg) 
#### 提示测试成功
![点击数据源](/images/datasourceJNDI/2018-05-07_131854.jpg)
#### 修改URL 为生产使用的RAC URL
```text
修改 每个实例的 ip port 以及集群的service_name

jdbc:oracle:thin:@(description=(address_list= 
(address=(host=192.168.1.1)(protocol=tcp)(port=1521))
(address=(host=192.168.1.2)(protocol=tcp)(port=1521))
(load_balance=yes)(failover=yes))(connect_data=(service_name=testdb)))
```  
![点击数据源](/images/datasourceJNDI/2018-05-07_132008.jpg) 
#### 继续点击测试配置
![点击数据源](/images/datasourceJNDI/2018-05-07_131854.jpg)
### 选择服务器  
![点击数据源](/images/datasourceJNDI/2018-05-07_132640.jpg) 
### 激活更改
![点击数据源](/images/datasourceJNDI/2018-05-07_132808.jpg) 
### OK 添加成功


 