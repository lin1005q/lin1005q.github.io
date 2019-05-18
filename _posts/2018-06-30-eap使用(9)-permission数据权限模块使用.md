---
key: eap使用9-permission数据权限模块使用
tags: [eap]
---

eap 最近支持了数据权限的配置使用

eg: 系统管理员可以查询全表数据 普通管理员只能查询到归属于自己部门下的数据

## 使用前的一点说明

### 支持的版本

因为使用了jdk8开发 jdk8同时使用的是 jdbc4.2版本 所以默认只支持8+ && 4.2

同时为了提高更好的使用性,使用了spel表达式 所以对spring 的版本会有要求 spring4+

### 优点

1. 跨数据库,理论上支持所有支持jdbc(4.2+)连接的数据库(可以通过使用低版本的jdk编译支持低版本).
2. 无侵入性 支持任何java环境 业务层代码不需要拼接sql
3. 支持 mybatis hibernate 等数据库框架
4. 支持 c3p0 dbcp2 等数据库连接池
5. 支持spel 比如支持按照角色配置

### 原理

jdbc是java平台连接数据库的标准 任何框架 都是通过`java.sql.Driver` 接口进行连接数据库

将数据库的配置修改为`代理Driver` 代理Driver 拦截到执行的sql语句后 对sql语句进行语法解析,生成语法树,根据配置规则增强sql
语句,再将生成的sql语句通过真实的数据库驱动类进行连接数据库.

### 后期扩展

对sql 运行的监控 做sql执行情况的统计报告,哪条sql最耗时,哪条sql频率最高等等,及早优化sql.

### 不足

1. 并未进行压测检测性能损耗.只能支持jdbc代理 其他非关系型数据库不支持.
2. 暂只支持prepareStatement预编译型
3. 目前只支持对sql增强 并不支持对返回结果集过滤
4. 暂只支持单数据源
5. 不支持JNDI

## 使用步骤

### pom.xml 添加依赖声明

```bash
<dependency>
    <groupId>com.hfvast.qlanguage</groupId>
    <artifactId>qlanguage_permission</artifactId>
    <version>${eap.version}</version>
</dependency>
```

### 添加配置文件

src/main/resource 下添加 配置文件 `hfvast-permission.properties`

文件内容如下

```properties
# 真实要使用的驱动类名
realDriverClassName=com.mysql.jdbc.Driver
# 默认启用过滤器
hfvast.permission.enableFilter=true
hfvast.permission.enableOrder=true
```

### 修改原始的数据库配置文件

|属性|driverClassName|
---|---|
原始值|com.mysql.jdbc.Driver|
修改后值|com.hfvast.permission.proxy.JDBCDriverProxy|
说明|直接替换|

|属性|url|
---|---|
原始值|jdbc:mysql://10.13.35.108:33066/eap|
修改后值|jdbc:hfvastmysql://10.13.35.108:33066/eap|
说明|增加hfvast|

### 添加过滤器(optional)

因为数据权限都是跟当前登录人相关的,所以可以添加在线检测过滤器,当检测到不是登录用户线程在调用(系统定时任务,或者是其他引擎)
直接返回结果集.代理层不代理,不拦截.提高性能,减少无畏的性能损耗

新建class `DataPermissionStaffOnlineFilter`

```java
package com.hfvast.maintenance;

import com.hfvast.permission.filter.PermissionFilter;
import com.hfvast.permission.filter.PermissionOrderFilter;
import com.hfvast.platform.security.StaffDetail;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * @author weihai4099
 * @date 2018/06/27 17:38
 */
public class DataPermissionStaffOnlineFilter implements PermissionOrderFilter {
    /**
     * 判断是否 是登录用户 是就进行下一个过滤器 否就退出代理层
     * @param stringBuffer
     * @param permissionFilter
     * @return
     */
    @Override
    public Boolean doFilter(StringBuffer stringBuffer, PermissionFilter permissionFilter) {
        return SecurityContextHolder.getContext() != null
                && SecurityContextHolder.getContext().getAuthentication() != null
                && SecurityContextHolder.getContext().getAuthentication().getPrincipal() != null;
    }

    /**
     * 过滤器链 排序 应该大于等于3 因为前面还有默认的过滤器
     * @return  
     */
    @Override
    public Integer getOrder() {
        return 3;
    }
}
```

这个过滤器根据不同框架不同,检测当前登录用户的方法也不同,所以需要使用方提供

src/main/resource 下新建目录 META-INF/services
新建文件文件名为:`com.hfvast.permission.filter.PermissionOrderFilter`
文件内容为:`com.hfvast.maintenance.DataPermissionStaffOnlineFilter` 即实现接口的类的全路径类名

事实上这是java spi 接口标准.

### 添加规则配置

字段|id|col_name|operator|table_name|type|value|value_type|enabled|enable_rule|
---|---|--------|--------|---------|----|-----|-----------|------|-----------|
说明|id|增强的列名|操作符号|表名| value类型时普通的定值还是动态的spel表达式|值|0是数字1是字符串|该规则是否生效|规则启用条件
基础配置|2|department_id|=|t_monitor_device| 1|@springspel.getDepartmentId()|0|1|T(com.hfvast.platform.util.QUtil).hasAnyRole('只读管理员')
高级配置|9|device_id|in|t_monitor_item|1|new String('SELECT id FROM t_monitor_device WHERE department_id = ').concat(@springspel.getDepartmentId())|1 |1|T(com.hfvast.platform.util.QUtil).hasAnyRole('只读管理员')|

解读这条规则 :

首先这条规则是生效的,当当前查询sql的登录人 拥有只读管理员这个角色时这条规则才会作用 添加 `where department_id =  @springspel.getDepartmentId()`这个spel表达式得到的值

例
* 原始sql `select * from t_monitor_device`
* 增强sql `select * from t_monitor_device where department_id = 28`
* 根据不同的人得到不同的部门id. 


可以通过spel表达式 支持关联 表增强
* 原始sql `select * from t_monitor_device`
* 增强sql `select * from t_monitor_device where department_id in (SELECT id FROM t_monitor_device WHERE department_id =@springspel.getDepartmentId())`

### 增加web页面对规则进行维护

* 如果是基于mybatis 直接对表`t_system_system_data_permissions` 进行crud即可
* 如果基于hibernate或者JPA 移步`com.hfvast.permission.conf.SystemPermissionEntity` 依赖jar中包含此类 注解式,只需要纳入扫描package路径下即可.
* 如果是基于最新的eap开发 platform模块已经支持 移步 `系统管理->数据权限配置`.
* 当然最重要的 要发布`com.hfvast.permission.spring.PermissionConfChangeEvent`事件 模块会捕获此事件刷新配置.

参考代码

```java
@Autowired
private ApplicationContext context;

public void test(){
    
    /**
     *   your code  cud代码
     */
    context.publishEvent(new PermissionConfChangeEvent("add"));
    
}
```

参考链接(get到思路)

* [TinyDac数据权限](http://www.tinygroup.org/docs/697473216636870322)




create by 老关&大王