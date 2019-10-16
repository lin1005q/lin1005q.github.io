---
date: 2019-10-16 15:29:00 +0800
key: Jenkinsfile代码质量检测范例
tags: [java高级]
---

```groovy
pipeline{
    agent any
 
    triggers {
	      // 每分钟判断一次代码是否有变化
	      pollSCM('*/5 * * * *')
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
                    withSonarQubeEnv('sonarqube') { // If you have configured more than one global server connection, you can specify its name
                      sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.6.0.1398:sonar'
                    }
                }
            }
        }
    }
}
```