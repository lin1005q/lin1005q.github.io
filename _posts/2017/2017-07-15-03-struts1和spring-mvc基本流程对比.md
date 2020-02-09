---
title: struts1和spring-mvc基本流程对比
date: 2017-07-15
tags: [java_web]
---
找到之前写的用spring mvc的应用.

项目结构:

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/1634013-e80439e49331dcc5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

流程大概:
1. tomcat启动
2. 读取web.xml文件.
  ```xml
<servlet>
  	<servlet-name>springmvc</servlet-name>
  	<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
  	<init-param>
  		<param-name>contextConfigLocation</param-name>
  		<param-value>classpath:applicationContext.xml</param-value>
  	</init-param>
  	<load-on-startup>1</load-on-startup>
  </servlet>
  <servlet-mapping>
  	<servlet-name>springmvc</servlet-name>
  	<url-pattern>*.do</url-pattern>
  </servlet-mapping>
  ```
这个和struts1差不多.交给一个主控制器.spring mvc是DispatcherServlet.它会在容器启动的时候初始化.
3. 读取spring mvc的配置文件,默认为classpath下的applicationContext.xml文件.内容如下:

  ```xml
<bean id="dbcp" class="org.apache.commons.dbcp.BasicDataSource">
		<property name="username" value="root"></property>
		<property name="password" value="123"></property>
		<property name="driverClassName" value="com.mysql.jdbc.Driver"></property>
		<property name="url" value="jdbc:mysql://localhost:3306/interview?useUnicode=true&amp;characterEncoding=utf8"></property>
	</bean>
	<!-- 获取mybatisSqlsessionFactory. -->
	<bean id="ssf" class="org.mybatis.spring.SqlSessionFactoryBean">
		<property name="dataSource" ref="dbcp"></property>
		<property name="mapperLocations" value="classpath:■■.■■■.interview.sql/*.xml"></property>
	</bean>
	
	<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
		<!-- 扫描包下接口实现 -->
		<property name="basePackage" value="■■.■■■.interview.dao"></property>
		<!-- 自动注入ssf -->
		
	</bean>
<mvc:annotation-driven/>
	<!-- 注解扫描路径 -->
	<context:component-scan base-package="■■.■■■.interview"/>
</beans>
  ```
4. 然后就等待请求来了

请求的处理流程,
1. 浏览器发一个请求`localhost:8080/interview/teacher/login.do?teacher_username=demo&teacher_password=demo`(get请求,可以看到参数,方便做日记,但正式不会用到get)
  *  可以看到,同struts1的很像`localhost:8080/struts1/login.do?username=demo&password=demo`只是字段名不一样.
2. tomcat收到http请求,将其交给interview[容器名应该是叫这个吧]()这个context容器.获取后缀是.do.将请求交给web.xml里面定义的DispatcherServlet.
  * struts是交给ActionServlet
3. 接下来spring mvc会在扫描注解的结果后,找到`/teacher`对应的这个类

```java
@Controller
@RequestMapping("/teacher")
public class TeacherController {
	@Resource
	private TeacherService teacherService;
	
	@RequestMapping("/log_in.do")
	@ResponseBody
	public InterviewResult log_in(@ModelAttribute("teacher") Teacher teacher){
		InterviewResult result=teacherService.log_in(teacher);
		return result;
		
	}
	
	@RequestMapping("/login.do")
	@ResponseBody
	public InterviewResult login(@ModelAttribute("teacher") Teacher teacher){
		System.out.println(teacher.toString());
		InterviewResult result=teacherService.addteacher(teacher);
		return result;
	}
	
	@RequestMapping("/update.do")
	@ResponseBody
	public InterviewResult updatepwd(String id,String oldpwd,String newpwd){
		InterviewResult result=teacherService.updatepwd(id, oldpwd, newpwd);
		return result;
	}
	
	@RequestMapping("/findname.do")
	@ResponseBody
	public InterviewResult findName(String id){
		InterviewResult result=teacherService.findname(id);
		return result;
	}
}
```
再继续找/login.do的对应方法.
```java
@RequestMapping("/login.do") 
@ResponseBody 
public InterviewResult login(@ModelAttribute("teacher") Teacher teacher){ 
  System.out.println(teacher.toString()); 
  InterviewResult result=teacherService.
  addteacher(teacher); 
  return result; 
}
```
  * 与struts1所不同的就是spring mvc不需要手动写路由和action的映射文件.当然了肯定会有性能消耗,忽略了很小.

4.  struts1在处理数据的时候,会将数据封装到一个对象,比如LoginForm.而spring mvc也可以自动封装到实体类,比struts更好的是,
  * 实体类不需要继承父类,单纯的po类.使用时在具体的action方法的参数列表中加入注解`@ModelAttribute("teacher") Teacher teacher`(Teacher是实体类)
  * 参数形式比较灵活,不需要像struts都需要进行映射实体Form,(struts后面也有动态的form,但都需要配置文件)..spring mvc直接在方法中可以定义,只要和页面form表单的name值对应就可以.
 
5. 之后就是处理的逻辑了,提供了,@Service  @Resource注解等
6. 返回的结果也可以是jsp, return一个String字符串,对应该字符串.jsp 文件.也可以是纯数据-json格式.

主要的不同点:
  * spring mvc的几个注解@Controller,@ModelAttribute就做了struts-config.xml文件做的事.真正到了公司就知道struts-config的文件有多少了,我是已经快疯掉了.
  * struts重点在c层和v层,路由控制和页面展示.模型层没有涉及.而spring mvc最牛的就在模型层,提供了ioc和di.(ssh就是要用spring的ioc和di)
  

简单做个对比.仅此而已.
