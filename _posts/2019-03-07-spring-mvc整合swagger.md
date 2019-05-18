---
title: spring-mvc整合swagger
key: swagger
tags: [java高级]
---

**spring mvc 整合 swagger 全部java config**

## 版本说明

1. spring 4.X
2. swagger 2.9.2


## 整合步骤

* Maven 添加依赖

```xml
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.9.2</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.9.2</version>
</dependency>
```

* 添加SwaggerConfig配置文件

```java
@Configuration
@EnableSwagger2
public class SwaggerConfig  extends WebMvcConfigurerAdapter {

    @Bean
    public Docket createRestApi(){

        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis( RequestHandlerSelectors.basePackage("com.hfvast.monitor"))
                .paths(PathSelectors.any())
                .build()
                ;

    }

    private ApiInfo apiInfo(){
        return new ApiInfoBuilder()
                .title("XXXX系统-v2")
                .description("XXXX系统-v2-后台接口文档")
                .version("0.0.1")
                .build();
    }

    /**
     * swagger 静态资源映射
     * @param registry
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        super.addResourceHandlers(registry);
        registry.addResourceHandler("/swagger-ui.html**").addResourceLocations("classpath:/META-INF/resources/swagger-ui.html");
        registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
    }

```

## 配置DispatcherServlet 的拦截路径

由于eap以前只拦截*.sp后缀的请求，添加了swagger以后，需要拦截其相关的请求，否则会404.

```java

    /**
     * @Description
     * @Author weihai4099
     * @Date 19-3-6 下午8:53
     *
     * @see springfox.documentation.swagger.web.ApiResourceController
     * @see springfox.documentation.swagger2.web.Swagger2Controller
     **/
    public class QWebAppInitializer implements WebApplicationInitializer {
    @Override
    public void onStartup(ServletContext servletContext) throws ServletException {
        System.out.println("WebApplicationInitializer onStartup ");

        AnnotationConfigWebApplicationContext rootContext = new AnnotationConfigWebApplicationContext();
        rootContext.register(WebConfig.class);

        servletContext.addListener(new HttpSessionEventPublisher());

        // 去除使用监听器启动任务 目前是使用 spring bean 的生命周期InitializingBean 来做任务启动
        // servletContext.addListener(new QuartzInitializerListener());

        // 去除之前javaConfig 定义的字符集过滤器 由于 servlet 规范没有对过滤器顺序 进行明确说明 所以移到web.xml 进行定义

        servletContext.addListener(new RequestContextListener());

        ServletRegistration.Dynamic dispatcher = servletContext.addServlet("dispatcher", new DispatcherServlet(rootContext));
        dispatcher.setLoadOnStartup(1);

        dispatcher.addMapping("*.sp","/swagger-ui.html","/v2/api-docs","/csrf","/swagger-resources","/swagger-resources/configuration/ui","/swagger-resources/configuration/security");


        dispatcher.setInitParameter("contextConfigLocation","classpath:spring-*.xml");

    }
}

```


## 说明

1. 使用spring boot是无需静态资源和servlet的拦截路径配置的。因为spring boot 默认将DispatcherServlet的拦截路径设置为`/`.
2. 使用`addResourceHandlers`进行内部的静态资源文件配置，将请求转发到jar包内。
3. 整体感觉做的不好，对业务有了侵入，而且扫描很慢。启动时耗时，没有用异步做。