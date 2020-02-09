---
title: SpringBoot自动配置原理
key: SpringBoot自动配置原理
tags: [java高级]
---

SpringBoot能够帮助开发人员简化很多配置。例如：

+ 不再需要配置`PropertyPlaceholderConfigurer`就能直接使用@Value注解
+ 不再需要手动配置，只需要添加`redis`的`maven`相关依赖，在配置文件中配置服务连接信息，即可使用`redis缓存`
+ 其他...

下面就说明一下SpringBoot是如何实现在几乎无配置的情况下就能实现自动配置的。

# 查看已启用、未启用的配置

首先我们先来看一下如何确认项目有哪些自动配置成功了或者失败了。

有3中方式可以在项目启动时在控制台查看当前项目已启用、未启用的自动配置：

1. 当项目以`java -jar`命令启动时，在启动配置后边追加`--debug`。

   示例：`java -jar SpringBootPrac *--debug*`

2. 在application.properties配置文件中配置：
   `debug=true`

3. 在启动配置*run configuration*中的*VM arguments*中配置：
   `-Ddebug`

配置好之后，启动项目，在控制台即可看到关于自动配置的报告。

1. 自动配置成功的报告，可能像这样：

   ![已启用报告](/images/SpringBootAutoConfiguration/positive.png)

2. 自动配置失败的报告，可能像这样：

   ![未启用报告](/images/SpringBootAutoConfiguration/negative.png)

在报告中，能够清晰的看到有哪些进行了自动配置，哪些没有成功配置，同时会有相关提示信息。

下面就来说一下实现的原理。

# 自动配置原理说明

## 从@SpringBootApplication注解说起

一切都要从SpringBoot项目的专属注解`@SpringBootApplication`说起：

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
		@Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {
    //other codes...
}
```

## 关键注解：@EnableAutoConfiguration

我们查看一下其组合进来的`@EnableAutoConfiguration`注解的代码：

```java
@SuppressWarnings("deprecation")
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(EnableAutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
    //other codes...   
}
```

注意这里组合进来的`@Import`注解。

`EnableAutoConfigurationImportSelector`使用`SpringFactoriesLoader.loadFactoryNames()`方法来扫描具有`META-INF/spring.factories`文件 的 jar 包。

## 核心包：org.springframework.boot.autoconfigure

而SpringBoot关于自动配置的源码都在`spring-boot-autoconfigure-1.3.x.x.jar`这个jar包内。

我们解压jar包，进入`META-INF`文件夹，发现刚好有一个`spring.factories`文件。

用文本编辑器打开这个`spring.factories`文件，我们会看到类似如下内容（截取部分）：

```
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration,\
org.springframework.boot.autoconfigure.context.PropertyPlaceholderAutoConfiguration,\
org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration,\
org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
```

> 这里的`\`代表当前行尚未结束，跟其紧邻的下一行是同一行内容。所以以上配置其实是一行配置，用逗号分隔多个值。

在这里我们看到了很多熟悉的字眼。且所有的配置类均以`AutoConfiguration`结尾。

## 举个例子：RedisAutoConfiguration

我们拿其中的`RedisAutoConfiguration` 举例，看一下具体是如何实现自动配置的。

```java
@Configuration
@ConditionalOnClass({ JedisConnection.class, RedisOperations.class, Jedis.class })
@EnableConfigurationProperties(RedisProperties.class)
public class RedisAutoConfiguration {
    //other codes...
}
```

#### 两个注解

有两个要说明的点：

1. 注解`@ConditionalOnClass`的作用：

   该注解表示：**当类路径下有指定的类的条件下，该注解配置的类生效。**

   在`RedisAutoConfiguration`中即表示，当`JedisConnection`、`RedisOperations`、`Jedis`三个类均能在类路径下找到的时候，该Redis的配置才启用。

2. 注解`@EnableConfigurationProperties`的作用：

   SpringBoot的注释中是这样说的：

   > **该注解支持以一种方便的方式来将带有`@ConfigurationProperties`注解的类注入为Spring容器的Bean。**

   这里的意思就是，`RedisAutoConfiguration`这个配置类的生效，依赖于`RedisProperties`这个类。

   那显然，`RedisProperties`这个类一定使用了``注解，我们验证下：

#### 实现配置文件中的自动提示功能

```java
@ConfigurationProperties(prefix = "spring.redis")
public class RedisProperties {

/**
* Database index used by the connection factory.
*/
private int database = 0;

/**
* Redis url, which will overrule host, port and password if set.
*/
private String url;
private String host = "localhost";
private String password;
private int port = 6379;

//other codes...
}
```

确实使用了`@ConfigurationProperties`注解。这个注解就**能够实现配置文件中配置属性的自动提示**功能。

拿基于`RedisProperties`的`Redis`配置来说，当你在配置文件中输入`spring.redis.`的时候，IDE中会弹出其所能支持的所有属性。这些都依赖于`@ConfigurationProperties`注解。

# 一点总结

截止到这里，SpringBoot的自动配置原理阐述完毕。在`XXXAutoConfiguration`中，可能还会使用`@ConditionalOnMissingBean`注解进行某些关键Bean的缺失条件下的处理操作。使用这个注解，既能保证当需要使用的Bean不存在于容器中时，将其补充到容器中，又能保证当Bean已经在其他位置引入到容器中时，放弃本配置中的引入，防止出现`Duplicate bean`的错误。

#  自己的自动配置

下面就来说一下，如何实现自己的自定义配置功能。需要如下几个步骤：

1. 在pom文件中添加支持自动配置的依赖：

   **注意打包方式要改为jar**

```xml
<dependencies>
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-autoconfigure</artifactId>
</dependency>
</dependencies>
```

2. 类型安全的配置类（如果需要），用于配置使用到的属性

3. 需要关注bean类（判断依据类），可能存在多个

4. 关键：**自动配置类**（如`com.hfvast.HelloAutoConfiguration`）

5. 在项目`src/resource`下新建`META-INF`文件夹，在其中新建`spring.factories`文件。

6. 在spring.factories文件中指定你的自动配置类名：
```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.hfvast.HelloautoConfiguration
```

完成如上的几个步骤后，将项目打成 jar 包部署在本地或者私服上，就可以供其他项目使用了。

# 进一步扩展（未完待续）

更进一步的，假如，我们极度不喜欢将`spring-boot-starter-parent`作为父项目（因为它太臃肿了，每次启动项目，都要依次扫描，确认有哪些自动配置可以完成），我们想实现自己的`starter pom`，又如何去做呢？

请等待下次更新...