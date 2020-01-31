---
date: 2020-01-29 23:30:00 +0800
tags: [转载,k8s]
sidebar:
  nav: k8s-zh
---

本文将主要分享以下几个方面的内容：

1.  需求来源
2.  GPU 的容器化
3.  Kubernetes 的 GPU 管理
4.  工作原理
5.  课后思考与实践

需求来源
----

2016 年，随着 AlphaGo 的走红和 TensorFlow 项目的异军突起，一场名为 AI 的技术革命迅速从学术圈蔓延到了工业界，所谓 AI 革命从此拉开了帷幕。

经过三年的发展，AI 有了许许多多的落地场景，包括智能客服、人脸识别、机器翻译、以图搜图等功能。其实机器学习或者说是人工智能，并不是什么新鲜的概念。而这次热潮的背后，云计算的普及以及算力的巨大提升，才是真正将人工智能从象牙塔带到工业界的一个重要推手。

![enter image description here](https://images.gitbook.cn/4bd72380-0acf-11ea-b817-4fc7306c5e8a)

与之相对应的，从 2016 年开始，Kubernetes 社区就不断收到来自不同渠道的大量诉求。希望能在 Kubernetes 集群上运行 TensorFlow 等机器学习框架。这些诉求中，除了前面课程所介绍的，像 Job 这些离线任务的管理之外，还有一个巨大的挑战：深度学习所依赖的异构设备及英伟达的 GPU 支持。

我们不禁好奇起来：Kubernetes 管理 GPU 能带来什么好处呢？本质上是成本和效率的考虑。由于相对 CPU 来说，GPU 的成本偏高。在云上单 CPU 通常是一小时几毛钱，而 GPU 的花费则是从单 GPU 每小时 10 元 ~30 元不等，这就要想方设法的提高 GPU 的使用率。 为什么要用 Kubernetes 管理以 GPU 为代表的异构资源？

具体来说是三个方面：

*   加速部署：通过容器构想避免重复部署机器学习复杂环境；
*   提升集群资源使用率：统一调度和分配集群资源；
*   保障资源独享：利用容器隔离异构设备，避免互相影响。

首先是加速部署，避免把时间浪费在环境准备的环节中。通过容器镜像技术，将整个部署过程进行固化和复用，如果同学们关注机器学习领域，可以发现许许多多的框架都提供了容器镜像。我们可以借此提升 GPU 的使用效率。 通过分时复用，来提升 GPU 的使用效率。当 GPU 的卡数达到一定数量后，就需要用到 Kubernetes 的统一调度能力，使得资源使用方能够做到用即申请、完即释放，从而盘活整个 GPU 的资源池。 而此时还需要通过 Docker 自带的设备隔离能力，避免不同应用的进程运行同一个设备上，造成互相影响。在高效低成本的同时，也保障了系统的稳定性。

GPU 的容器化
--------

上面了解到了通过 Kubernetes 运行 GPU 应用的好处，通过前面的学习也知道，Kubernetes 是容器调度平台，而其中的调度单元是容器，所以在学习如何使用 Kubernetes 之前，我们先了解一下如何在容器环境内运行 GPU 应用。

### 容器环境下使用 GPU 应用

在容器环境下使用 GPU 应用，实际上不复杂。主要分为两步：

*   构建支持 GPU 的容器镜像；
*   利用 Docker 将该镜像运行起来，并且把 GPU 设备和依赖库映射到容器中。

### 如何准备 GPU 容器镜像

有两个方法准备：

*   直接使用官方深度学习容器镜像

比如直接从 docker.hub 或者阿里云镜像服务中寻找官方的 GPU 镜像，包括像 TensorFlow、Caffe、PyTorch 等流行的机器学习框架，都有提供标准的镜像。这样的好处是简单便捷，而且安全可靠。

*   基于 Nvidia 的 CUDA 镜像基础构建

当然如果官方镜像无法满足需求时，比如你对 TensorFlow 框架进行了定制修改，就需要重新编译构建自己的 TensorFlow 镜像。这种情况下，我们的最佳实践是：依托于 Nvidia 官方镜像继续构建，而不要从头开始。

如下图中的 TensorFlow 例子所示，这个就是以 CUDA 镜像为基础，开始构建自己的 GPU 镜像。

![enter image description here](https://images.gitbook.cn/78d403d0-0acf-11ea-9c4d-396a5a73a7fc)

### GPU 容器镜像原理

要了解如何构建 GPU 容器镜像，先要知道如何要在宿主机上安装 GPU 应用。

如下图左边所示，最底层是先安装 Nvidia 硬件驱动；再到上面是通用的 CUDA 工具库；最上层是 PyTorch、TensorFlow 这类的机器学习框架。上两层的 CUDA 工具库和应用的耦合度较高，应用版本变动后，对应的 CUDA 版本大概率也要更新；而最下层的 Nvidia 驱动，通常情况下是比较稳定的，它不会像 CUDA 和应用一样，经常更新。

![enter image description here](https://images.gitbook.cn/a2db71e0-0acf-11ea-99ae-6d54e597f04b)

同时 Nvidia 驱动需要内核源码编译，如上图右侧所示，英伟达的 GPU 容器方案是：在宿主机上安装 Nvidia 驱动，而在 CUDA 以上的软件交给容器镜像来做。同时把 Nvidia 驱动里面的链接以 Mount Bind 的方式映射到容器中。这样的一个好处是：当你安装了一个新的 Nvidia 驱动之后，你就可以在同一个机器节点上运行不同版本的 CUDA 镜像了。

### 如何利用容器运行 GPU 程序

有了前面的基础，我们就比较容易理解 GPU 容器的工作机制。下图是一个使用 Docker 运行 GPU 容器的例子。

![enter image description here](https://images.gitbook.cn/b3652600-0acf-11ea-b817-4fc7306c5e8a)

我们可以观察到，在运行时刻一个 GPU 容器和普通容器之间的差别，仅仅在于需要将宿主机的设备和 Nvidia 驱动库映射到容器中。上图右侧反映了 GPU 容器启动后，容器中的 GPU 配置。右上方展示的是设备映射的结果，右下方显示的是驱动库以 Bind 方式映射到容器后，可以看到的变化。通常大家会使用 Nvidia-docker 来运行 GPU 容器，而 Nvidia-docker 的实际工作就是来自动化做这两个工作。其中挂载设备比较简单，而真正比较复杂的是 GPU 应用依赖的驱动库。对于深度学习，视频处理等不同场景，所使用的一些驱动库并不相同。这又需要依赖 Nvidia 的领域知识，而这些领域知识就被贯穿到了 Nvidia 的容器之中。

Kubernetes 的 GPU 管理
-------------------

### 如何部署 GPU Kubernetes

首先看一下如何给一个 Kubernetes 节点增加 GPU 能力，我们以 CentOS 节点为例。

![enter image description here](https://images.gitbook.cn/c64155a0-0acf-11ea-9c4d-396a5a73a7fc)

如上图所示：

*   首先安装 Nvidia 驱动；

由于 Nvidia 驱动需要内核编译，所以在安装 Nvidia 驱动之前需要安装 gcc 和内核源码。

*   第二步通过 yum 源，安装 Nvidia Docker2；

安装完 Nvidia Docker2 需要重新加载 Docker，可以检查 Docker 的 daemon.json 里面默认启动引擎已经被替换成了 Nvidia，也可以通过 `docker info` 命令查看运行时刻使用的 runC 是不是 Nvidia 的 runC。

*   第三步是部署 Nvidia Device Plugin。

从 Nvidia 的 `git repo` 下去下载 Device Plugin 的部署声明文件，并且通过 `kubectl create` 命令进行部署。这里 Device Plugin 是以 deamonset 的方式进行部署的。这样我们就知道，如果需要排查一个 Kubernetes 节点无法调度 GPU 应用的问题，需要从这些模块开始入手，比如我要查看一下 Device Plugin 的日志，Nvidia 的 runC 是否配置为 Docker 默认 runC，以及 Nvidia 驱动是否安装成功。

### 验证部署 GPU Kubernetes 结果

当 GPU 节点部署成功后，我们可以从节点的状态信息中发现相关的 GPU 信息。

*   一个是 GPU 的名称，这里是 nvidia.com/gpu；
*   另一个是它对应的数量，如下图所示是 2，表示在该节点中含有两个 GPU。

![enter image description here](https://images.gitbook.cn/f6221c00-0acf-11ea-b453-8900bb88b7f0)

### 在 Kubernetes 中使用 GPU 的 yaml 样例

站在用户的角度，在 Kubernetes 中使用 GPU 容器还是非常简单的。只需要在 Pod 资源配置的 limit 字段中指定 nvidia.com/gpu 使用 GPU 的数量，如下图样例中我们设置的数量为 1；然后再通过 `kubectl create` 命令将 GPU 的 Pod 部署完成。

![enter image description here](https://images.gitbook.cn/03ca5b10-0ad0-11ea-99ae-6d54e597f04b)

### 查看运行结果

部署完成后可以登录到容器中执行 `nvidia-smi` 命令观察一下结果，可以看到在该容器中使用了一张 T4 的 GPU 卡。说明在该节点中的两张 GPU 卡其中一张已经能在该容器中使用了，但是节点的另外一张卡对于改容器来说是完全透明的，它是无法访问的，这里就体现了 GPU 的隔离性。

![enter image description here](https://images.gitbook.cn/1b081010-0ad0-11ea-b817-4fc7306c5e8a)

工作原理
----

### 通过扩展的方式管理 GPU 资源

Kubernetes 本身是通过插件扩展的机制来管理 GPU 资源的，具体来说这里有两个独立的内部机制。

![enter image description here](https://images.gitbook.cn/241ae880-0ad0-11ea-b453-8900bb88b7f0)

*   第一个是 Extend Resources，允许用户自定义资源名称。而该资源的度量是整数级别，这样做的目的在于通过一个通用的模式支持不同的异构设备，包括 RDMA、FPGA、AMD GPU 等等，而不仅仅是为 Nvidia GPU 设计的；
*   Device Plugin Framework 允许第三方设备提供商以外置的方式对设备进行全生命周期的管理，而 Device Plugin Framework 建立 Kubernetes 和 Device Plugin 模块之间的桥梁。它一方面负责设备信息的上报到 Kubernetes，另一方面负责设备的调度选择。

### Extended Resource 的上报

Extend Resources 属于 Node-level 的 API，完全可以独立于 Device Plugin 使用。而上报 Extend Resources，只需要通过一个 PACTH API 对 Node 对象进行 status 部分更新即可，而这个 PACTH 操作可以通过一个简单的 curl 命令来完成。这样，在 Kubernetes 调度器中就能够记录这个节点的 GPU 类型，它所对应的资源数量是 1。

![enter image description here](https://images.gitbook.cn/43532820-0ad0-11ea-99ae-6d54e597f04b)

当然如果使用的是 Device Plugin，就不需要做这个 PACTH 操作，只需要遵从 Device Plugin 的编程模型，在设备上报的工作中 Device Plugin 就会完成这个操作。

### Device Plugin 工作机制

介绍一下 Device Plugin 的工作机制，整个 Device Plugin 的工作流程可以分成两个部分：

*   一个是启动时刻的资源上报；
*   另一个是用户使用时刻的调度和运行。

![enter image description here](https://images.gitbook.cn/88db4c10-0ad0-11ea-b817-4fc7306c5e8a)

Device Plugin 的开发非常简单。主要包括最关注与最核心的两个事件方法：

*   其中 ListAndWatch 对应资源的上报，同时还提供健康检查的机制。当设备不健康的时候，可以上报给 Kubernetes 不健康设备的 ID，让 Device Plugin Framework 将这个设备从可调度设备中移除；
*   而 Allocate 会被 Device Plugin 在部署容器时调用，传入的参数核心就是容器会使用的设备 ID，返回的参数是容器启动时，需要的设备、数据卷以及环境变量。

### 资源上报和监控

对于每一个硬件设备，都需要它所对应的 Device Plugin 进行管理，这些 Device Plugin 以客户端的身份通过 GRPC 的方式对 kubelet 中的 Device Plugin Manager 进行连接，并且将自己监听的 Unis socket api 的版本号和设备名称比如 GPU，上报给 kubelet。 我们来看一下 Device Plugin 资源上报的整个流程。总的来说，整个过程分为四步，其中前三步都是发生在节点上，第四步是 kubelet 和 api-server 的交互。

![enter image description here](https://images.gitbook.cn/53f82c70-0ad0-11ea-9c4d-396a5a73a7fc)

第一步是 Device Plugin 的注册，需要 Kubernetes 知道要跟哪个 Device Plugin 进行交互。这是因为一个节点上可能有多个设备，需要 Device Plugin 以客户端的身份向 Kubelet 汇报三件事情。

*   我是谁？就是 Device Plugin 所管理的设备名称，是 GPU 还是 RDMA；
*   我在哪？就是插件自身监听的 unis socket 所在的文件位置，让 kubelet 能够调用自己；
*   交互协议，即 API 的版本号。

第二步是服务启动，Device Plugin 会启动一个 GRPC 的 Server。在此之后 Device Plugin 一直以这个服务器的身份提供服务让 kubelet 来访问，而监听地址和提供 API 的版本就已经在第一步完成了。

第三步，当该 GRPC server 启动之后，kubelet 会建立一个到 Device Plugin 的 ListAndWatch 的长连接， 用来发现设备 ID 以及设备的健康状态。当 Device Plugin 检测到某个设备不健康的时候，就会主动通知 kubelet。而此时如果这个设备处于空闲状态，kubelet 会将其移除可分配的列表。但是当这个设备已经被某个 Pod 所使用的时候，kubelet 就不会做任何事情，如果此时杀掉这个 Pod 是一个很危险的操作。

第四步，kubelet 会将这些设备暴露到 Node 节点的状态中，把设备数量发送到 Kubernetes 的 api-server 中。后续调度器可以根据这些信息进行调度。

需要注意的是 kubelet 在向 api-server 进行汇报的时候，只会汇报该 GPU 对应的数量。而 kubelet 自身的 Device Plugin Manager 会对这个 GPU 的 ID 列表进行保存，并用来具体的设备分配。而这个对于 Kubernetes 全局调度器来说，它不掌握这个 GPU 的 ID 列表，它只知道 GPU 的数量。这就意味着在现有的 Device Plugin 工作机制下，Kubernetes 的全局调度器无法进行更复杂的调度。比如说想做两个 GPU 的亲和性调度，同一个节点两个 GPU 可能需要进行通过 NVLINK 通讯而不是 PCIe 通讯，才能达到更好的数据传输效果。在这种需求下，目前的 Device Plugin 调度机制中是无法实现的。

### Pod 的调度和运行的过程

![enter image description here](https://images.gitbook.cn/cfa565e0-0ad0-11ea-b453-8900bb88b7f0)

Pod 想使用一个 GPU 的时候，它只需要像之前的例子一样，在 Pod 的 Resource 下 limits 字段中声明 GPU 资源和对应的数量（比如nvidia.com/gpu: 1）。Kubernetes 会找到满足数量条件的节点，然后将该节点的 GPU 数量减 1，并且完成 Pod 与 Node 的绑定。

绑定成功后，自然就会被对应节点的 kubelet 拿来创建容器。而当 kubelet 发现这个 Pod 的容器请求的资源是一个 GPU 的时候，kubelet 就会委托自己内部的 Device Plugin Manager 模块，从自己持有的 GPU 的 ID 列表中选择一个可用的 GPU 分配给该容器。

此时 kubelet 就会向本机的 DeAvice Plugin 发起一个 Allocate 请求，这个请求所携带的参数，正是即将分配给该容器的设备 ID 列表。

Device Plugin 收到 AllocateRequest 请求之后，它就会根据 kubelet 传过来的设备 ID，去寻找这个设备 ID 对应的设备路径、驱动目录以及环境变量，并且以 AllocateResponse 的形式返还给 kubelet。 AllocateResponse 中所携带的设备路径和驱动目录信息，一旦返回给 kubelet 之后，kubelet 就会根据这些信息执行为容器分配 GPU 的操作，这样 Docker 会根据 kubelet 的指令去创建容器，而这个容器中就会出现 GPU 设备。并且把它所需要的驱动目录给挂载进来，至此 Kubernetes 为 Pod 分配一个 GPU 的流程就结束了。

课后思考与实践
-------

### 课后总结

在本次课程中，我们一起学习了在 Docker 和 Kubernetes 上使用 GPU。GPU 的容器化：

*   如何去构建一个 GPU 镜像
*   如何直接在 Docker 上运行 GPU 容器

利用 Kubernetes 管理 GPU 资源：

*   如何在 Kubernetes 支持 GPU 调度
*   如何验证 Kubernetes 下的 GPU 配置
*   调度 GPU 容器的方法

Device Plugin 的工作机制：

*   资源的上报和监控
*   Pod 的调度和运行

思考：

*   目前的缺陷
*   社区常见的 Device Plugin

### Device Plugin 机制的缺陷

最后我们来思考一个问题，现在的 Device Plugin 是否完美无缺？

需要指出的是 Device Plugin 整个工作机制和流程上，实际上跟学术界和工业界的真实场景有比较大的差异。这里最大的问题在于 GPU 资源的调度工作，实际上都是在 kubelet 上完成的。而作为全局的调度器对这个参与是非常有限的，作为传统的 Kubernetes 调度器来说，它只能处理 GPU 数量。一旦你的设备是异构的，不能简单地使用数目去描述需求的时候，比如我的 Pod 想运行在两个有 nvlink 的 GPU 上，这个 Device Plugin 就完全不能处理。 更不用说在许多场景上，我们希望调度器进行调度的时候，是根据整个集群的设备进行全局调度，这种场景是目前的 Device Plugin 无法满足的。

更为棘手地是，在 Device Plugin 的设计和实现中，像 Allocate 和 ListAndWatch 的 API 去增加可扩展的参数也是没有作用的。这就是当我们使用一些比较复杂的设备使用需求的时候，实际上是无法通过 Device Plugin 来扩展 API 实现的。因此目前的 Device Plugin 设计涵盖的场景其实是非常单一的，是一个可用但是不好用的状态。这就能解释为什么像 Nvidia 这些厂商都实现了一个基于 Kubernetes 上游代码进行 fork 了自己解决方案，也是不得已而为之。

### 社区的异构资源调度方案

![enter image description here](https://images.gitbook.cn/edcde330-0ad0-11ea-99ae-6d54e597f04b)

*   第一个是 Nvidia 贡献的调度方案，这是最常用的调度方案；
*   第二个是由阿里云服务团队贡献的 GPU 共享的调度方案，其目的在于解决用户共享 GPU 调度的需求，欢迎大家一起来使用和改进；
*   下面的两个 RDMA 和 FPGA 是由具体厂商提供的调度方案。