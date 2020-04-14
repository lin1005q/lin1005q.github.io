---
date: 2020-03-07 11:43:00 +0800
key: 使用helm-controller-简化容器云平台应用商店的开发开发手册
tags: [云原生]
---

熟练的阅读并且进行相应的开发，大概需要对以下知识的了解：

* k8s rest api 模型需要了解。
* http协议需要熟练掌握。
* openapi规范了解。
* linux熟练掌握。
* helm的理论架构了解。
* k8s crd 的理解，controller概念掌握，rbac权限模型的理解。
* helm私库index.yaml的理解与使用。
* core dns的配置与使用。

整体结构图

![](/images/captain/20200414233834.png)

## helm是啥

helm是k8s的包管理器，也是k8s平台复杂应用部署事实上的标准。包含了应用打包，部署，升级，回滚，卸载等符合生命周期管理的功能。

### 架构变动

helm从v2到v3的版本升级，移除了重要的一个组件tiller，整体架构更简洁。

### helm架构在云管理平台开发中的不足

helm至今为止，官方仍然没有ga版的api。chart的下载，部署，升级，卸载，全部依赖cli。在多集群环境下cli很难满足平台的业务要求。

通过查看github issue，社区大概有两种解决思路： 

* 封装cli成api。这种方式仍然存在每个集群需要通过ssh或者ansible的方式部署helm二进制文件到master节点上，给底层部署工作添加负担。
* CRD。将helm的核心能力打包成docker镜像，部署到k8s集群中，以controller的方式提供能力。利用crd的方式完成release的部署，卸载，升级，回滚等业务动作。

cli方式最大的问题就在于不符合云原生的思想，而且cli的方式和helm版本锁定，如果要升级helm，需要重新适配解析console内容。
crd的问题在于，官方目前还没有ga。但仍然期待controller的方式。

我们团队最初使用第一种方式进行了尝试，但效果不理想。恰巧当时发现灵雀云开源了helm v3 controller captain，所以基于社区captain的进行了第二次尝试，并最终完成了功能开发。
 
当时，在github搜索`helm controller`，发现了两个仓库，一个是rancher提供的controller，一个是灵雀云提供的。经过简单的测试，captain一次性安装并测试成功，并结合内部的讨论，最终决定基于captain进行开发。

## captain

github: [https://github.com/alauda/captain](https://github.com/alauda/captain)

### 介绍

*The  [Helm 3 Design Proposal](https://github.com/helm/community/blob/master/helm-v3/000-helm-v3.md)  exists for a while and currently it is still under heavy development. Captain comes as the first implementation of Helm v3 Controller based on the Proposal.
This project is based on the core  [helm](https://github.com/helm/helm)  v3 code, acting as a library. Since it's not officially released yet (alpha stage for now), some modifications were made to help implement this controller on a fork:  [alauda/helm](https://github.com/alauda/helm)  (will be deprecated once Helm's library is released).*

captain是灵雀云开源的`helm v3 controller`。其内部依赖helm library。所以核心的逻辑与helm client是一致的。等到后期helm官方正式ga后，可以迁移回官方正式版本，这对于以面向接口编程的java来说，so easy。

**基于Apache 2.0协议开源**

captain内部将helm部署成deployment。

### 快速安装测试

安装步骤：
```bash
kubectl create ns captain-system
kubectl create clusterrolebinding captain --serviceaccount=captain-system:default --clusterrole=cluster-admin
kubectl apply -n captain-system -f https://raw.githubusercontent.com/alauda/captain/master/artifacts/all/deploy.yaml
```
卸载：
```bash
kubectl delete -n  captain-system -f https://raw.githubusercontent.com/alauda/captain/master/artifacts/all/deploy.yaml
kubectl delete ns captain-system
```
安装nginx chart
```yaml
kind: HelmRequest
apiVersion: app.alauda.io/v1alpha1
metadata:
  name: nginx-ingress
spec:
  chart: stable/nginx-ingress
```
查看部署结果
```bash
root@VM-16-12-ubuntu:~/demo# kubectl get pods
NAME                                             READY   STATUS    RESTARTS   AGE
nginx-ingress-controller-57987f445c-9rhv5        1/1     Running   0          16s
nginx-ingress-default-backend-7679dbd5c9-wkkss   1/1     Running   0          16s
root@VM-16-12-ubuntu:~/demo# kubectl get hr
NAME            CHART                  VERSION   NAMESPACE   ALLCLUSTER   PHASE    AGE
nginx-ingress   stable/nginx-ingress             default                  Synced   23s
```

### chart repo问题

captain默认自带stable的helm官方仓库，helm官方的仓库地址本身没有问题，但是chart镜像中如果使用了被墙了的docker镜像，无法下载。测试的时候是使用的aliyun提供的仓库地址[https://developer.aliyun.com/hub/](https://developer.aliyun.com/hub/)。这样captain controller才能顺利的将chart镜像下载成功。

当测试结束时，我们需要将k8s与内网的chart私库进行打通，需要新建一个ChartRepo的yaml文件

```yaml
apiVersion: app.alauda.io/v1alpha1
kind: ChartRepo
metadata:
  name: cloud
  namespace: captain-system
spec:
  url: https://harbor.offline/chartrepo/library
```
然后使用`kubectl create -f fileName`添加到k8s中，需要注意的是，我们使用了harbor做docker镜像和helm镜像的管理，因为docker的问题，我们使用了自签的证书，captain在根据地址同步的时候，会校验证书，这个问题我们也和官方进行了沟通，得到了解决，目前captain已经ga，可以直接使用，不需要担心证书的问题。

### RBAC权限问题

云平台的管理中，我们通过servicecount进行k8s api的使用，当安装了captain之后，不同于命令行使用user account，我们需要额外的一步追加权限的动作

`kubectl create clusterrolebinding default --serviceaccount=default:default --clusterrole=cluster-admin`

### captain sdk问题

captain 官方目前只提供了go和python的sdk，基于此，我们肯定要封装一个captain的java sdk。

在架构底层，我们使用k8s官方的[sdk](https://github.com/kubernetes-client/java)进行开发。

基于crd和k8s openapi的简单了解，结合[官方的说明](https://github.com/kubernetes-client/java/blob/e679a13248cfdf437460292cab0635c5cd54adcc/docs/generate-model-from-third-party-resources.md)，尝试性的进行了sdk生成的动作，结果失败了,详细见[issue](https://github.com/alauda/captain/issues/49)我们也联系了作者，得知captain并没有基于schema做校验，内部使用了webhook进行的校验。基于这样的背景，直接使用openapi规范生成sdk的路不通，后面我们直接使用了`kubectl -v9`的方式进行报文的验证，以及代码的开发。

使用kubectl命令行进行任意操作时，追加`-v9`参数，可以获取详细的http报文信息

```bash
root@master:/home/kylin# kubectl get pod -v9
I0414 22:42:53.981748   16582 loader.go:359] Config loaded from file:  /root/.kube/config
I0414 22:42:54.042173   16582 round_trippers.go:419] curl -k -v -XGET  -H "Accept: application/json;as=Table;v=v1beta1;g=meta.k8s.io, application/json" -H "User-Agent: kubectl/v1.15.5 (linux/amd64) kubernetes/20c265f" 'https://192.168.4.139:6443/api/v1/namespaces/default/pods?limit=500'
I0414 22:42:54.077898   16582 round_trippers.go:438] GET https://192.168.4.139:6443/api/v1/namespaces/default/pods?limit=500 200 OK in 35 milliseconds
I0414 22:42:54.077959   16582 round_trippers.go:444] Response Headers:
I0414 22:42:54.078006   16582 round_trippers.go:447]     Content-Type: application/json
I0414 22:42:54.078054   16582 round_trippers.go:447]     Date: Tue, 14 Apr 2020 14:42:54 GMT
I0414 22:42:54.078394   16582 request.go:947] Response Body: {"kind":"Table","apiVersion":"meta.k8s.io/v1beta1","metadata":{"selfLink":"/api/v1/namespaces/default/pods","resourceVersion":"14332801"},"columnDefinitions":完整报文太长，略去！}]}}}]}
I0414 22:42:54.092067   16582 get.go:564] no kind "Table" is registered for version "meta.k8s.io/v1beta1" in scheme "k8s.io/kubernetes/pkg/api/legacyscheme/scheme.go:30"
NAME                                READY   STATUS              RESTARTS   AGE
busybox                             1/1     Running             970        39d
nginx-1585049022-b4f4c56c9-dvspz    1/1     Running             24         12d
nginx-deployment-5bd886c88c-28d6q   0/1     Pending             0          2d1h
nginx-deployment-5bd886c88c-968pd   0/1     MatchNodeSelector   0          4d3h
nginx-deployment-5bd886c88c-dnh8q   0/1     MatchNodeSelector   0          4d3h
nginx-deployment-5bd886c88c-pk9xz   0/1     Pending             0          2d1h
```

再结合k8s官方的java sdk提供的[CustomObjectsApi](https://github.com/kubernetes-client/java/blob/a874e75af026d1833e3e35c3d54d4fbcfe99faf0/kubernetes/docs/CustomObjectsApi.md)。比较轻松的就开发了一整套chart镜像生命周期对应的接口。

#### 部署

 ```java
var customObjectsApi = new  CustomObjectsApi(apiClient);
var json = new JsonObjectBuilder()  
        .set("apiVersion", "app.alauda.io/v1alpha1")  
        .set("kind", "HelmRequest")  
        .set("metadata", new JsonObjectBuilder().set("name", name).build())  
        .set("spec", new JsonObjectBuilder()  
                .set("chart", chart)  
                .set("namespace", namespace)  
                .set("releaseName", name)  
                .set("values", Map2JsonUtil.map2Json(params))  
                .set("version", version)  
        ).build();

customObjectsApi.createNamespacedCustomObject("app.alauda.io","v1alpha1", "default", "helmrequests", json, null);
```

#### 卸载

```java
var customObjectsApi = new  CustomObjectsApi(apiClient);
customObjectsApi.deleteNamespacedCustomObject("app.alauda.io", "v1alpha1", "default","helmrequests", "test-nginx",new  V1DeleteOptions().gracePeriodSeconds(0L).propagationPolicy("Foreground"),null, null, null);
```
#### 升级

这里可以选择打patch或者直接replace，和k8s的概念是一致的。

#### 回滚

captain并没有像deployment原生的提供了对回滚的支持，需要自己将每次安装或者升级的参数进行外部保存，再重新replace指定版本的参数，进行模拟回滚。

## 其他说明
* 整体上，我们使用了三周的时间完成了应用商店第一版的开发，以及页面接口联调。这比使用cli方式的预期快了很多，而且我们的ansbile部署脚本上只需要再额外添加两行安装captain的脚本。
* 使用私有helm repo，默认情况下，集群内的coredns将非集群内的地址转发到本机的`/etc/resolv.conf`,这个时候一定要确保k8s宿主机的`/etc/resolv.conf`dns地址修改为内网的dns server地址。否则captain controller找不到私有的helm repo，错误是 timeout。
* 在开发过程中，如果遇到问题无法定位，可以直接查看captain-controller的log，来进行处理。
* 网络问题最好部署一个busybox，内置了nslookup，wget等工具。方便网络检测。
  ```yaml
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
  ```
  使用`kubectl create -f busybox.yaml`完成busybox部署，使用`kubectl exec -it busybox sh`进入容器内部，使用`nslookup`，`wget`等进行网络检测。