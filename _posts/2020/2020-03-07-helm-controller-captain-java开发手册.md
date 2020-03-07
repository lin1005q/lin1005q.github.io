---
date: 2020-03-07 11:43:00 +0800
key: helm-controller-captain-java开发手册
tags: [云原生]
---

熟练的阅读并且进行相应的开发，大概需要对以下知识的了解：
* k8s rest api 模型需要了解。
* http协议需要熟练掌握。
* openapi规范了解。
* linux熟练掌握。
* helm的理论架构了解。
* k8s crd 的了解，controller概念掌握，rbac权限模型要了解。
* helm私库需要对dns的了解，配置。

## helm是啥

helm是k8s的包管理器

### 架构变动

helm从v2到v3的版本升级，移除了重要的一个组件tiller。整体架构更简洁。

### helm架构在云平台开发中的不足

helm至今为止，官方仍然没有ga版的api。包的下载，部署，升级，卸载，全部依赖cli。在多集群环境下cli很难达到业务要求。

社区有多种解决思路：

* 封装cli成api。但仍然存在每个集群需要通过ssh或者ansible的方式部署helm二进制文件到master节点上，给底层部署工作添加负担。
* k8s controller。将helm的核心能力打包成docker镜像，部署到k8s集群中。利用crd的方式完成release的部署，卸载，升级，回滚等业务动作。

cli方式最大的问题就在于违背了云原生的思想，而且cli的方式和helm版本锁定。如果要升级，需要重新适配解析console内容。

controller的问题在于，官方目前还没有ga。但仍然期待controller的方式。

在github搜索`helm controller`，发现了两个仓库，一个是rancher提供的controller，一个是灵雀云提供的。经过简单的比较测试，决定拿灵雀云做个demo出来。

## captain

captain是灵雀云开源的`helm v3 controller`。其内部依赖helm library。所以核心的逻辑与helm client是一致的。等到后期helm官方正式ga后，可以迁移回官方正式版本。

captain内部将helm controller部署成deployment。

github：https://github.com/alauda/captain

### sdk

我们使用k8s官方的[sdk](https://github.com/kubernetes-client/java)进行开发。

基于crd和k8s openapi的简单了解，结合[官方的说明](https://github.com/kubernetes-client/java/blob/e679a13248cfdf437460292cab0635c5cd54adcc/docs/generate-model-from-third-party-resources.md)，进行了sdk生成的动作，结果失败了,详细见[issue](https://github.com/alauda/captain/issues/49)

所以就只能使用`v9`大法了。

使用kubectl命令行部署helm release时，追加v9参数，可以获取详细的http报文信息，再结合k8s官方的java sdk提供的[CustomObjectsApi](https://github.com/kubernetes-client/java/blob/a874e75af026d1833e3e35c3d54d4fbcfe99faf0/kubernetes/docs/CustomObjectsApi.md).

比较轻松的就开发了一个简单的部署chart镜像的接口。

```java
CustomObjectsApi customObjectsApi = new CustomObjectsApi(apiClient);

var json = new JsonObjectBuilder()
        .set("apiVersion", "app.alauda.io/v1alpha1")
        .set("kind", "HelmRequest")
        .set("metadata", new JsonObjectBuilder().set("name", "test-nginx").build())
        .set("spec", new JsonObjectBuilder()
                .set("chart", "aliyun/nginx")
                .set("namespace", "default")
                .set("releaseName", "test-nginx")
                .set("values", Map2JsonUtil.map2Json(params))
                .set("version", null)
        ).build();

customObjectsApi.createNamespacedCustomObject("app.alauda.io",
        "v1alpha1", "default", "helmrequests", json, null);

```


同样的卸载应用

```java
CustomObjectsApi customObjectsApi = new CustomObjectsApi(apiClient);
customObjectsApi.deleteNamespacedCustomObject("app.alauda.io", "v1alpha1", "default",
        "helmrequests", "test-nginx",
        new V1DeleteOptions().gracePeriodSeconds(0L).propagationPolicy("Foreground"),
        null, null, null);
```

升级应用

这里可以选择打patch或者直接replace，和k8s的概念是一致的。


### 网络问题

1. helm官方的仓库地址本身没有问题，但是chart镜像中使用了被墙了的docker镜像，无法下载。测试的时候是使用的aliyun提供的仓库地址[https://developer.aliyun.com/hub/](https://developer.aliyun.com/hub/)。这样captain controller才能顺利的将chart镜像下载成功。

2. 使用私有helm repo，过程中会遇到ssl check的问题。这个问题captain官方已经修复，可以直接使用。

3. 使用私有helm repo，默认情况下，集群内的coredns将非集群内的地址转发到本机的`/etc/resolv.conf`,这个时候一定要确保k8s宿主机的`/etc/resolv.conf`dns地址修改为内网的dns server地址。否则captain controller找不到私有的helm repo，错误是 timeout。

4. 网络问题最好部署一个busybox，内置了nslookup，wget等工具。方便网络检测。


        apiVersion: v1
        kind: Pod
        metadata:
        name: busybox
        namespace: default
        spec:
        containers:
        - name: busybox
            image: busybox:1.28.4
            command:
            - sleep
            - "3600"
            imagePullPolicy: IfNotPresent
        restartPolicy: Always

    使用`kubectl create -f busybox.yaml`完成busybox部署，使用`kubectl exec -it busybox sh`进入容器内部，使用nslookup，wget等进行网络检测。


