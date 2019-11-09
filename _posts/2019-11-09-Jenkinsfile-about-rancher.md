---
date: 2019-11-09 11:02:00 +0800
key: Jenkinsfile-about-rancher
tags: [linux]
---

jenkins对接rancher进行持续部署

## 重点说明
1. Jenkinsfile的方式是以后的主流
2. jenkins plugins 中心的rancher plugin 是对应rancher 1.x版本，而现在一般都安装2.x，所以直接使用plugin无效。
3. 还有一种方式是使用rancher-cli，就是在jenkins宿主机安装jenkins脚本工具，进行认证后，在jenkinsfile中通过sh的方式直接调用。
4. 这里说明的是使用rancher的http api的方式进行调用
5. rancher必须使用https，所以要注意ssl证书的处理，比较麻烦，如果可以申请公有的最好用公有的，避免很多麻烦。
6. 如果使用自签名证书，在调用http接口时，会产生证书校验失败的问题，curl测试可以使用`-k`去除校验，快速测试。
7. Jenkinsfile中发送http请求需要安装`http request plugin`，使用的是groovy语言。这个插件提供了`ignoreSslErrors`设置项。
8. 配置Jenkinsfile时不可以勾选`Use Groovy Sandbox`。有一个api不在snadbox的允许范围中。
9. api协议需要自己去找，没有详细的接口文档。rancher会在api响应中将可以进行的操作的url显示出来。
10. http认证使用Basic Auth。

## Jenkinsfile
```conf
pipeline{
    agent any
    stages{
        stage('rancher'){
            steps{
                script{
                    def rancherUrl ="https://192.168.1.1:4443/v3/project/c-j8lt8:p-mgzdk/workloads/deployment";
                    def RANCHER_API_KEY = "rancher";
                    def rancherNamespace = "microservice";
                    def rancherService ="microservice-gate";
                    def dockerImage = "harbor.offline/microservice/microservice-gate";

                    echo "查询服务信息"
                    def response = httpRequest acceptType: 'APPLICATION_JSON', authentication: "${RANCHER_API_KEY}", contentType: 'APPLICATION_JSON', httpMode: 'GET', responseHandle: 'LEAVE_OPEN', timeout: 10, url: "${rancherUrl}:${rancherNamespace}:${rancherService}", ignoreSslErrors:true
                    def serviceInfo = new groovy.json.JsonSlurperClassic().parseText(response.content)
                    response.close()
                    echo "进行docker镜像名比较"
                    if (dockerImage.equals(serviceInfo.containers[0].image)) {  
                        echo "发送重新部署的请求"
                        response = httpRequest acceptType: 'APPLICATION_JSON', authentication: "${RANCHER_API_KEY}", contentType: 'APPLICATION_JSON', httpMode: 'PUT', requestBody: "${response.content}",responseHandle: 'NONE', timeout: 10, url: "${rancherUrl}:${rancherNamespace}:${rancherService}", ignoreSslErrors:true
                    } else {
                        echo "修改docker镜像名"
                        serviceInfo.containers[0].image = dockerImage
                        def updateJson = new groovy.json.JsonOutput().toJson(serviceInfo)
                        echo "发送重新部署的请求"
                        httpRequest acceptType: 'APPLICATION_JSON', authentication: "${RANCHER_API_KEY}", contentType: 'APPLICATION_JSON', httpMode: 'PUT', requestBody: "${updateJson}", responseHandle: 'NONE', timeout: 10, url: "${rancherUrl}:${rancherNamespace}:${rancherService}", ignoreSslErrors:true
                        echo "结束!!"
                    }

                }
            }
        }
    }
}

```

## 参考

1. [Docker+Jenkins+Pipeline实现持续集成（二）java项目构建](https://www.jianshu.com/p/56c90b03c481)
2. [使用Jenkins更新Rancher服务](https://www.jianshu.com/p/c4b95c056679)
3. [RANCHER API(官方)](https://rancher.com/docs/rancher/v2.x/en/api/)
4. [HTTP Request Plugin](https://jenkins.io/doc/pipeline/steps/http_request/)