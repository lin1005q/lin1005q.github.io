---
title: spring-mvc整合mybatis-plus
key: mybatis-plus
tags: [sql,java高级]
---

**spring mvc 整合 mybatis plus 全部java config**

## 版本说明

1. spring 4.X
2. mybatis-plus 3.1.0


## 整合步骤

* Maven 添加依赖

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus</artifactId>
    <version>3.1.0</version>
</dependency>
```

**引入 MyBatis-Plus 之后请不要再次引入 MyBatis 以及 MyBatis-Spring，以避免因版本差异导致的问题。**


* 添加MybatisPlusConfig配置文件

```java
import com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.mapper.MapperScannerConfigurer;
import org.springframework.beans.factory.FactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;


@Configuration
@EnableTransactionManagement
public class MybatisPlusConfig {

    @Bean
    public FactoryBean sqlSessionFactory(DataSource dataSource) {
        // FactoryBean 需要替换为 mybatis plus 的实现
        MybatisSqlSessionFactoryBean mybatisSqlSessionFactoryBean = new MybatisSqlSessionFactoryBean();
        mybatisSqlSessionFactoryBean.setDataSource(dataSource);
        return mybatisSqlSessionFactoryBean;
    }

    @Bean
    public MapperScannerConfigurer mapperScannerConfigurer() {
        MapperScannerConfigurer scannerConfigurer = new MapperScannerConfigurer();
        // 扫描包的路径 需要添加多个，第一个是mybatis-plus 第二个是自己项目的     *.** 是任意目录下的
        scannerConfigurer.setBasePackage("com.baomidou.mybatisplus.*.**,com.hfvast.*.**");
        scannerConfigurer.setSqlSessionFactoryBeanName("sqlSessionFactory");
        return scannerConfigurer;
    }

    @Bean
    public DataSourceTransactionManager transactionManager(DataSource dataSource) {
        DataSourceTransactionManager transactionManager = new DataSourceTransactionManager();
        transactionManager.setDataSource(dataSource);
        return transactionManager;
    }
}

```

## 测试

```java

package com.hfvast.mybatis.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import static com.baomidou.mybatisplus.annotation.IdType.AUTO;

@Data
@TableName("t_monitor_device")
public class User {
    @TableId(type = AUTO)
    private Integer id;

    private String name;

    @TableField(exist = false)
    private String password;
    
    
}
```

```java

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.hfvast.MybatisPlusConfig;
import com.hfvast.mybatis.entity.User;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.annotation.Rollback;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.transaction.annotation.Transactional;

@ContextConfiguration(classes = {MybatisPlusConfig.class, DBConfig.class})
@RunWith(SpringJUnit4ClassRunner.class)
public class MybatisTest {

    @Autowired
    private BaseMapper<User> userBaseMapper;

    @Test
    @Transactional(rollbackFor=NullPointerException.class)
    @Rollback(false)
    public void myBatisConfigSelect(){
       List<User> users = userBaseMapper.selectList(new QueryWrapper<>());
        System.out.println("..............."+users);
    }
}
```


## 日常使用说明

1. mybatis-plus提供了一些通用的curd方法，一些通用的方法直接使用mybatis-plus
2. 实体类上添加@Data注解（lombok自动添加 get set 等等方法）
3. 实体类上添加@TableName("t_monitor_device")（plus 注解 指定表名）
4. 主键字段上添加@TableId(type = AUTO)（plus主键 指定主键字段 type 设定主键的类型）
5. 其他字段上添加@TableField(exist = false)（plus主键 实体类存在的字段，表中不存在的字段）
6. 在自己写的业务service中直接注入`BaseMapper<T>` T必须为添加了主键的实体的类名。
7. 如果需要写定制的sql语句，需要自己写接口，添加@Mapper注解，让mybatis-plus扫描到，并自己在方法上添加sql语句的相关注解。
8. 后续补充。