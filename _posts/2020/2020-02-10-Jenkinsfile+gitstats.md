---
date: 2020-02-10 22:57:00 +0800
key: Jenkinsfile+gitstats
tags: [其他]
---

使用jenkinsfile搭配gitstats生成代码提交量报表

## build image

```bash
docker pull ubuntu
docker run -it ubuntu /bin/bash
apt-get update
apt install gitstats -y && exit
docker commit containerId wang1010q/gitstats
docker push wang1010q/gitstats
```

```bash
FROM ubuntu
RUN apt-get update && apt install gitstats -y
```

## Jenkinsfile

```groovy
pipeline {
    agent {
        docker { image 'wang1010q/gitstats' }
    }
    parameters {
        string(name: 'codeBranch', defaultValue: 'master', description: '选择一个分支')
        string(name: 'codeSource', defaultValue: 'https://**.com/**.git', description: '输入一个仓库地址（仅支持https协议）')
        choice(name: 'codeDate', choices: ['1', '2', '3','4'], description: '统计之前几周的数据')
    }
    stages {
        stage('SCM') {
            steps{
               git branch: '${codeBranch}',credentialsId: '247072b5-f9fb-48e1-aa09-5b8ad875868f',url :'${codeSource}'
            }
        }
        
        stage('gitstats'){
            steps{
                sh 'gitstats -c start_date=${codeDate}.weeks . 123'
            }
            
        }
        stage('push html'){
            steps{
                script{
                    publishHTML (target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '123',
                        reportFiles: 'index.html',
                        reportName: "Gitstats Report"
                    ])
                }
            }
        }
    }
}
```