---
date: 2021-05-25 10:00:00 +0800
key: 在docker容器内获知cpu和内存限制
tags: [docker]
---

## 内存

* /sys/fs/cgroup/memory/memory.limit_in_bytes

## cpu

* /sys/fs/cgroup/cpu/cpu.cfs_period_us cpu分配的周期(微秒），默认为100000
* /sys/fs/cgroup/cpu/cpu.cfs_quota_us 表示该control group限制占用的时间（微秒），默认为-1，表示不限制。如果设为50000，表示占用50000/10000=50%的CPU,如果设为200000，表示占用200%的cpu。