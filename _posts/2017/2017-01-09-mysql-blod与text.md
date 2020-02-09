---
title: mysql_blod与text
date: 2017-01-09 16:45:14
tags: [sql]
---

### 在存储大文本是,使用text去存储
```sql
INSERT INTO t_wt_order_message SET orderid =?,
message = CONCAT(IFNULL(message, ' '),?) 
ON DUPLICATE KEY 
UPDATE 
  message = CONCAT(IFNULL(message, ' '),?)

```

在进行存储的时候,发生字符集错误,原因之前使用blob,但blob是没有字符集的,存储的是二进制

>[MySQL下，text 、blob的比较](http://blog.csdn.net/a809146548/article/details/49428453)


### ON DUPLICATE KEY UPDATE

要求效果 有则更新,无则插入
如上例,
使用`ON DUPLICATE KEY`(主键unique)
在得到返回值时,当插入时,返回影响1行,当更新是返回影响2行.

>[为什么mysql的ON DUPLICATE KEY UPDATE在有重复数据时 ，影响的数据栏: 2](http://www.iteye.com/problems/73122)


