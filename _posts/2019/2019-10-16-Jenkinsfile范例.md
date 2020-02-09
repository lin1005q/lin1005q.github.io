---
date: 2019-10-16 15:29:00 +0800
key: Jenkinsfile范例
tags: [java高级]
---


## sonarqube maven plugin 原始的执行脚本

```bash
mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.6.0.1398:sonar -Dsonar.host.url=localhost -Dsonar.login=admin -Dsonar.password=admin -Dsonar.projectKey=xxx -Dsonar.projectName=xxx系统 -Dsonar.sourceEncoding=UTF-8 -Dsonar.language=java
```

## git 代码质量检测范例

```groovy
pipeline{
    agent any
 
    triggers {
	      // 每分钟判断一次代码是否有变化
	      pollSCM('H/5 * * * *')
    }

    tools {
        maven 'maven'
    }
 
    stages {
        stage('SCM') {
            steps{
               git branch: 'master',credentialsId: '8384ed7d-b716-4ce6-aaeb-1619d4da52d7',url :'https://***.git'
            }
        }

        stage('Build'){
            steps{
                sh 'mvn clean package -Dmaven.test.skip=true'
                echo 'build success'
            }
        }
        
        stage('SonarQube analysis') {
            steps{
                script{
                    def scannerHome = tool 'sonarqube';
                    withSonarQubeEnv('sonarqube') { 
                      sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.6.0.1398:sonar -Dsonar.projectName=XXX系统'
                    }
                }
            }
        }
    }
}
```

## svn 代码质量检测范例

**注意: 需要将sonarqube server 中的 Disable the SCM Sensor 设置为true  路径:配置->配置->SCM->Disable the SCM Sensor**

```groovy
pipeline{
    agent any

    triggers {
        // 每分钟判断一次代码是否有变化
        pollSCM('H/5 * * * *')
    }

    tools {
        maven 'maven'
    }

    stages {
        stage('Build'){
            steps{
                sh 'mvn clean package'
                // sh 'printenv'
                echo 'build success'
            }
        }

        stage('SonarQube analysis') {
            steps{
                script{
                    def scannerHome = tool 'sonarqube';
                    withSonarQubeEnv('sonarqube') {
                      sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.6.0.1398:sonar -Dsonar.projectName=XXX系统'
                    }
                }
            }
        }
    }
}
```

## Jenkinsfile定时删除tag为none 的docker image

```groovy
pipeline{
    agent any
    
    triggers{
        cron('H 0 * * *')
    }
    stages{
        stage('test'){
            steps{
                sh '''
                
                num=`docker images|grep none| wc -l`;
                if [ $num -ne 0 ];then 
                  docker images|grep none|awk '{print $3}'|xargs docker rmi;
                  echo "delete none image success"
                fi

                '''
            }
        }
        
    }
}
```
