---
date: 2020-01-29 23:30:00 +0800
tags: [转载,k8s]
sidebar:
  nav: k8s-zh
---

本节课程主要分享以下三方面的内容：

1.  operator 概述
2.  operator framework 实战
3.  工作流程

operator 概述
-----------

### 基本概念

首先介绍一下本节所涉及到的基本概念。

*   **CRD (Custom Resource Definition)**：允许用户自定义 Kubernetes 资源，是一个类型；
*   **CR (Custom Resourse)**：CRD 的一个具体实例；
*   **webhook**：它本质上是一种 HTTP 回调，会注册到 apiserver 上。在 apiserver 特定事件发生时，会查询已注册的 webhook，并把相应的消息转发过去。

按照处理类型的不同，一般可以将其分为两类：一类可能会修改传入对象，称为 mutating webhook；一类则会只读传入对象，称为 validating webhook。

*   **工作队列**：controller 的核心组件。它会监控集群内的资源变化，并把相关的对象，包括它的动作与 key，例如 Pod 的一个 Create 动作，作为一个事件存储于该队列中；
*   **controller**：它会循环地处理上述工作队列，按照各自的逻辑把集群状态向预期状态推动。不同的 controller 处理的类型不同，比如 replicaset controller 关注的是副本数，会处理一些 Pod 相关的事件；
*   **operator**：operator 是描述、部署和管理 kubernetes 应用的一套机制，从实现上来说，可以将其理解为 CRD 配合可选的 webhook 与 controller 来实现用户业务逻辑，即 operator = CRD + webhook + controller。

### 常见的 operator 工作模式

![](https://images.gitbook.cn/71d188b0-169f-11ea-9e6b-1b93daaa75ec)

工作流程：

1.  用户创建一个自定义资源 (CRD)；
2.  apiserver 根据自己注册的一个 pass 列表，把该 CRD 的请求转发给 webhook；
3.  webhook 一般会完成该 CRD 的缺省值设定和参数检验。webhook 处理完之后，相应的 CR 会被写入数据库，返回给用户；
4.  与此同时，controller 会在后台监测该自定义资源，按照业务逻辑，处理与该自定义资源相关联的特殊操作；
5.  上述处理一般会引起集群内的状态变化，controller 会监测这些关联的变化，把这些变化记录到 CRD 的状态中。

这里是从 High-Level 大概介绍一下，后面会结合案例重新梳理。

operator framework 实战
---------------------

### operator framework 概述

在开始之前，首先介绍一下 operator framework。它实际上给用户提供了 webhook 和 controller 的框架，它的主要意义在于帮助开发者屏蔽了一些通用的底层细节，不需要开发者再去实现消息通知触发、失败重新入队等，只需关注被管理应用的运维逻辑实现即可。

主流的 operator framework 主要有两个：**kubebuilder** 和 **operator-sdk**。

两者实际上并没有本质的区别，它们的核心都是使用官方的 controller-tools 和 controller-runtime。不过细节上稍有不同，比如 kubebuilder 有着更为完善的测试与部署以及代码生成的脚手架等；而 operator-sdk 对 ansible operator 这类上层操作的支持更好一些。

### kuberbuildere 实战

这里的实战选用的是 kuberbuilder。案例选用的是阿里云对外开放的 kruise 项目下的 SidercarSet。

SidercarSet 的功能就是负责给 Pod 插入 sidecar 容器（也称为辅助容器），例如可以插入一些监控，日志采集来丰富这个 Pod 的功能，然后根据插入的状态、Pod 的状态反过来更新 SidercarSet 以记录这些辅助容器的状态。

#### Step 1：初始化

**操作：**

新建一个 GitLab 项目，运行

    kubebuilder init --domain=kruise.io
    

**参数解读：**

domain 指定了后续注册 CRD 对象的 Group 域名。

**效果解读：**

拉取依赖代码库、生成代码框架、生成 Makefile/Dockerfile 等工具文件。

我们来看一下它具体生成的内容（为了方便演示，实际生成文件做了部分删减）：

![](https://images.gitbook.cn/b977d1b0-169f-11ea-a523-0bd97445ce75)

具体的内容大家可以在实战的时候自己进行详细的确认。

#### Step 2：创建 API

**操作：**

运行

    kubebuilder create api --group apps --version v1alpha1 --kind SidecarSet --namespace=false
    

实际上不仅会创建 API，也就是 CRD，还会生成 Controller 的框架。

**参数解读：**

*   group 加上之前的 domian 即此 CRD 的 Group: apps.kruise.io；
*   version 一般分三种，按社区标准：
    *   v1alpha1：此 API 不稳定，CRD 可能废弃、字段可能随时调整，不要依赖；
    *   v1beta1：API 已稳定，会保证向后兼容，特性可能会调整；
    *   v1：API 和特性都已稳定；
*   kind：此 CRD 的类型，类似于社区原生的 Service 的概念；
*   namespaced：此 CRD 是全局唯一还是 namespace 唯一，类似 node 和 Pod。

它的参数基本可以分为两类。group、version、kind 基本上对应了 CRD 元信息的三个重要组成部分。这里给出了一些常见的标准，大家实际使用的时候可以参考一下。namespaced 则用于指定我们刚刚创建的 CRD 时全局唯一的（如 node）还是 namespace 唯一的（如 Pod）。这里用了 false，即指定 SidecarSet 为全局唯一的。

**效果解读：**

生成了 CRD 和 controller 的框架，后面需要手工填充代码。

实际结果如下图所示：

![](https://images.gitbook.cn/0c5cd3d0-16a0-11ea-a523-0bd97445ce75)

我们重点关注是图中蓝色字体部分。sidecarset_types.go 就是定义 CRD 的地方，需要我们填充。sidecarset_controller.go 则用于定义 controller，同样需要进行填充。

#### Step 3：填充 CRD

1\. 生成的 CRD 位于 pkg/apis/apps/v1alpha1/sidecarset_types.go，通常需要进行如下两个操作：

**(1) 调整注释**

code generator 依赖注释生成代码，因此有时需要调整注释。以下列出了本次实战中 SidecarSet 需要调整的注释：

*   `+genclient:nonNamespaced`：生成非 namespace 对象；
*   `+kubebuilder:subresource:status`：生成 status 子资源；
*   `+kubebuilder:printcolumn:name="MATCHED",type='integer',JSONPath=".status.matchedPods",description="xxx": kubectl get sidecarset`：后续展示相关。

**(2) 填充字段**

填充字段是令用户的 CRD 实际生效、实际有意义的重要部分。

*   SidecarSetSpec：填充 CRD 描述信息；
*   SidecarSetStatus：填充 CRD 状态信息。

2\. 填充完运行 make 重新生成代码即可

需要注意的是，研发人员无需参与 CRD 的 grpc 接口、编解码等 controller 的底层实现。

实际的填充如下图所示：

![](https://images.gitbook.cn/86618d60-16a0-11ea-b942-d94b94287f55)

SidecarSet 的功能是给 Pod 注入 Sidecar，为了完成该功能，我们在 SidecarSetSpec（左图） 定义了两个主要信息：一个是用于选择哪些 Pod 需要被注入的 Selector；一个是定义 Sidecar 容器的 Containers。

在 SidecarSetStatus（右图）中定义了状态信息，MatchedPods 反映的是该 SidecarSet 实际匹配了多少 Pod，UpdatedPods 反映的是已经注入了多少，ReadyPods 反映的则是有多少 Pod 已经正常工作了。

完整的内容可以参考 ([https://github.com/openkruise/kruise](https://github.com/openkruise/kruise))。

#### Step 4：生成 webhook 框架

1\. 生成 mutating webhook，运行：

    kubebuilder alpha webhook --group apps --version v1alpha1 --kind SidecarSet --type=mutating --operations=create
    

    kubebuilder alpha webhook --group core --version v1 --kind Pod --type=mutating --operations=create
    

2\. 生成 validating webhook，运行：

    kubebuilder alpha webhook --group apps --version v1alpha1 --kind SidecarSet --type=validating --operations=create,update
    

**参数解读：**

*   group/kind 描述需要处理的资源对象；
*   type 描述需要生成哪种类型的框架；
*   operations 描述关注资源对象的哪些操作。

**效果解读：**

*   生成了 webhook 框架，后面需要手工填充代码。

实际生成结果如下图所示：

![](https://images.gitbook.cn/aec47330-16a0-11ea-8478-cb869aae9121)

我们执行了三条命令，分别生成了三个不同的需要填充的 handler 中（上图蓝色字体部分）。这里先不提，在下一步填充操作中再对其详细讲解。

#### Step 5：填充 webhook

生成的 webhook handler 分别位于：

*   \- pkg/webhook/default_server/sidecarset/mutating/xxx_handler.go
*   \- pkg/webhook/default_server/sidecarset/validating/xxx_handler.go
*   \- pkg/webhook/default_server/pod/mutating/xxx_handler.go

需要改写、填充的一般包括以下两个部分：

*   **是否需要注入 K8s client**：取决于除了传入的 CRD 以外是否还需要其它资源。在本实战中，不仅要关注 SidecarSet，同时还要注入 Pod，因此需要注入 K8s client；
*   **填充 webhook 的关键方法**：即 mutatingSidecarSetFn 或 validatingSidecarSetFn。由于待操作资源对象指针已经传入，因此直接调整该对象属性即可完成 hook 的工作。

我们来看一下实际的填充结果。

![](https://images.gitbook.cn/ea3c9a00-16a0-11ea-8812-dd393aeead92)

因为第四步我们定义了三个：sidecarset mutating、sidecarset mutaing、pod mutating。

先来看上图左侧的 sidecarset mutating，首先是 setDefaultSidecarSet 把默认值设置好，这也是 mutaing 最常做的事情。

上图右侧 validating 也是非常的标准，也是对 SidecarSet 一些字段进行校验。

关于 pod mutaing 这里没有做展示，这里面有些不同，这里面的 mutaingSidecarSetFn 不是进行默认值设置，而是获取 setDefaultSidecarSet 的数值，然后注入到 Pod 里面。

#### Step 6：填充 controller

生成的 controller 框架位于 pkg/controller/sidecarset/sidecarset_controller.go。主要有三点需要进行修改：

*   **修改权限注释。**框架会自动生成形如 `//+kuberbuilder:rbac;groups=apps,resources=deployments/status,verbs=get;update;path` 的注释，我们可以按照自己的需求修改，该注释最终会生成 rbac 规则；
*   **增加入队逻辑。**缺省的代码框架会填充 CRD 本身的入队逻辑（如 SidecarSet 对象的增删改都会加入工作队列），如果需要关联资源对象的触发机制（如 SidecarSet 也需关注 Pod 的变化），则需手工新增它的入队逻辑；
*   **填充业务逻辑。**修改 Reconcile 函数，循环处理工作队列。Reconcile 函数主要完成「根据 Spec 完成业务逻辑」和「将业务逻辑结果反馈回 status」两部分。需要注意的是，如果 Reconcile 函数出错返回 err，默认会重新入队。

我们来看一下 SidecarSet 的 Controller 的填充结果：

![](https://images.gitbook.cn/07c0e810-16a1-11ea-8478-cb869aae9121)

addPod 中先取回该 Pod 对应的 SidecarSet 并将其加入队列以便 Reconcile 进行处理。

Reconcile 将 SidercarSet 取出之后，根据 Selector 选择匹配的 Pod，最后根据 Pod 当前的状态信息计算出集群的状态，然后回填到 CRD 的状态中。

SidecarSet 的工作流程
----------------

最后我们再来重新梳理一下 SidecarSet 的工作流程以便我们理解 operator 是如何工作的。

![](https://images.gitbook.cn/1317e420-16a1-11ea-94bc-f516225b4bcb)

1.  用户创建一个 SidecarSet；
2.  webhook 收到该 SidecarSet 之后，会进行缺省值设置和配置项校验。这两个操作完成之后，会完成真正的入库，并返回给用户；
3.  用户创建一个 Pod；
4.  webhook 会拿回对应的 SidecarSet，并从中取出 container 注入 Pod 中，因此 Pod 在实际入库时就已带有了刚刚的 sidecar；
5.  controller 在后台不停地轮询，查看集群的状态变化。第 4 步中的注入会触发 SidecarSet 的入队，controller 就会令 SidecarSet 的 UpdatedPods 加 1。

以上就是 SidecarSet 前期一个简单的功能实现。

这里我们再补充一个问题。一般的 webhook 由 controller 来完成业务逻辑、状态更新，但这个不是一定的，两者之一可以不是必须的。在以上的示例中就是由 webhook 完成主要的业务逻辑，无需 controller 的参与。

本节总结
----

本节课的主要内容就到此为止了，这里为大家简单总结一下：

*   Operator 是 CRD 配合 可选的 webhook 和 controller，在 Kubernetes 体系下扩展用户业务逻辑的一套机制；
*   kubebuilder 是社区认可度很高的一种官方、标准化 Operator 框架；
*   按照上文实战步骤，填充用户自定义代码，就可以很方便的实现一个 Operator。