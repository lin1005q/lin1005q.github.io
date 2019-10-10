---
date: 2019-10-10 09:38:00 +0800
key: jetty-maven-plugin配置JNDI数据源
tags: [java高级]
---

web项目通过使用JNDI配置数据源,可以将测试包直接部署到生产服务器.避免生产上线需要二次打包,二次打包可能打错的问题.

现在的项目一般使用项目内配置的方式配置数据库连接url,username,password等属性,在项目内创建DataSource数据源.这样存在每个环境都必须打一个包的弊端.

spring boot 通过原生支持多环境的配置文件,并通过优先级策略完成配置的优先使用完成项目包多环境启动.

而在spring cloud等SOA,微服务体系中,倡导使用分布式配置中心(spring cloud config)来将代码与配置完全分离.

**各有各的优劣**.

以下是jetty-maven-plugin 配置jndi数据源的步骤.

## 配置jetty-maven-plugin


注意jetty插件的版本,其他版本没有测试.

```xml
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.18.v20190429</version>
  <dependencies>
    <!-- 添加数据库驱动包 -->
    <dependency>
      <groupId>com.oracle</groupId>
      <artifactId>ojdbc6</artifactId>
      <version>12.1.0.2.0</version>
    </dependency>
  </dependencies>
  <configuration>
    <httpConnector>
      <port>8085</port>
    </httpConnector>
    <stopKey>stop</stopKey>
    <stopPort>8889</stopPort>
    <webAppConfig>
      <!-- 数据源配置文件 -->
      <jettyEnvXml>src/main/resources/jetty.xml</jettyEnvXml>
      <!-- jetty 内置的web.xml 比项目的web.xml 优先级高 -->
      <defaultsDescriptor>src/main/resources/webdefault.xml</defaultsDescriptor>
      <!-- 应用的二级应用名 -->
      <contextPath>/onu.webservice</contextPath>
    </webAppConfig>
  </configuration>
</plugin>
```

## 添加jetty.xml

```xml
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
    <New id="Server" class="org.eclipse.jetty.plus.jndi.Resource">
        <Arg>
            <Ref refid="Server"/><!-- 范围为整个 Server -->
        </Arg>
        <Arg>jdbc/datasource</Arg>
        <Arg>
            <New class="oracle.jdbc.pool.OracleDataSource">
                <Set name="URL">jdbc:oracle:thin:@127.0.0.1:1521:xa</Set>
                <Set name="User">admin</Set>
                <Set name="Password">admin</Set>
            </New>
        </Arg>
    </New>
</Configure>

```

## 添加webdefault.xml

[文件较长点击下载](/bash/webdefault.xml)

重点是添加了下面这一段jndi的配置文件

```xml
<resource-ref>
  <description>MySQL DataSource Reference</description>
  <res-ref-name>jdbc/datasource</res-ref-name>
  <res-type>javax.sql.DataSource</res-type>
  <res-auth>Container</res-auth>
</resource-ref>
```

## 使用

其中`jdbc/datasource`为Datasource的名字，在程序中可以通过以下方法获得数据源：

```java
context = new InitialContext();
DataSource source = (DataSource)context.lookup("java:comp/env/jdbc/datasource");
```

>[jetty 9 JNDI(Datasource) & Jaas & ssl配置](https://my.oschina.net/jianming/blog/372937)