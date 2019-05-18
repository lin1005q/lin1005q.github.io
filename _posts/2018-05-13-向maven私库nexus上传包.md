---
title: 
key: 向maven私库nexus上传包
tags: [maven,shell,eap]
---

## 前提条件

1. 有一个nexus私库已经搭建好
2. 拥有上传权限的账号
3. 一个jar

## 开始

前几天有人将这个依赖提交到svn
```xml
<dependency>
    <groupId>org.opennebula.client</groupId>
    <artifactId>one-client</artifactId>
    <version>2.0.1-SNAPSHOT</version>
</dependency>
```

maven 编译提示找不到依赖jar.

很显然SNAPSHOT版本的jar是不会在maven center 中央库存在的.

这时,最好的办法就是将第三方的jar包上传到自己的maven私库中.

私库安装略过,私库账号什么的配置在**eap使用(2)-工具安装**中.

运行以下脚本

linux
```bash
mvn deploy:deploy-file -DgroupId=org.opennebula.client \
 -DartifactId=one-client -Dversion=2.0.1-SNAPSHOT -Dpackaging=jar \
 -Dfile=one-client-2.0.1-SNAPSHOT.jar \
 -Durl=http://soft126.com:8081/nexus/content/repositories/snapshots \
 -DrepositoryId=snapshots
```

window
```bash
mvn deploy:deploy-file -DgroupId=org.opennebula.client -DartifactId=one-client -Dversion=2.0.1-SNAPSHOT -Dpackaging=jar -Dfile=E:\qqDownload\one-client-2.0.1-SNAPSHOT.jar -Durl=http://soft126.com:8081/nexus/content/repositories/snapshots -DrepositoryId=snapshots
```

提示: 
* -Dfile 本地jar的(绝对)路径
* -Durl 私库对应的仓库路径
* -DrepositoryId 仓库ID


**pom.xml 添加相对应的私库配置**


然后执行`mvn install`


之后 其他的一些第三方的jar(eg: ojdbc aliyunsdk)都可以放到maven(nexus)进行维护,不需要每个项目组成员copy文件

## 本地打包

附上将jar打到本地仓库的**command**.

```bash
mvn install:install-file -DgroupId=org.opennebula.client -DartifactId=one-client -Dversion=2.0.1-SNAPSHOT -Dpackaging=jar -Dfile=E:\qqDownload\one-client-2.0.1-SNAPSHOT.jar
```




