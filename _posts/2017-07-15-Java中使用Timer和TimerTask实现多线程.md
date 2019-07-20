---
date: 2017-07-15 19:04
title: Java中使用Timer和TimerTask实现多线程
tags: [java基础,多线程，转载]
---

>[2013年05月30日 09:04供稿中心： 课工场](http://www.bdqn.cn/news/201305/9303.shtml)

#### 摘要：Timer是一种线程设施，用于安排以后在后台线程中执行的任务。可安排任务执行一次，或者定期重复执行，可以看成一个定时器，可以调度TimerTask。

---
Timer是一种线程设施，用于安排以后在后台线程中执行的任务。可安排任务执行一次，或者定期重复执行，可以看成一个定时器，可以调度TimerTask。TimerTask是一个抽象类，实现了Runnable接口，所以具备了多线程的能力。

测试代码:
```java
import java.util.TimerTask;
public class OneTask extends TimerTask{
    private int id;
    public OneTask(int id){
        this.id = id;
    }
    @Override
    public void run() {
        System.out.println("线程"+ id +":  正在 执行。。"); 
        //System.gc();
    }   
}
```

然后主程序代码为：
```java
import java.util.Date;
import java.util.Timer;
   
public class Test1 {
    public static void main(String[] args) {
        Timer timer = new Timer(); 
		timer.schedule(new OneTask(1), 5000);// 5秒后启动任务
          
        OneTask secondTask= new OneTask(2);
        timer.schedule(secondTask, 1000, 3000);// 1秒后启动任务,以后每隔3秒执行一次线程
          
        Date date = new Date();
        timer.schedule(new OneTask(3),new Date(date.getTime()+1000));//以date为参数，指定某个时间点执行线程
          
//      timer.cancel();
//      secondTask.cancel();
        System.out.println("end in main thread...");
    }
}

```

Timer里面有4个schedule重载函数。而且还有两个scheduleAtFixedRate：

`void scheduleAtFixedRate(TimerTask task, Date firstTime, long period)`安排指定的任务在指定的时间开始进行重复的固定速率执行。`void scheduleAtFixedRate(TimerTask task, long delay, long period)`安排指定的任务在指定的延迟后开始进行重复的固定速率执行。
使用`scheduleAtFixedRate`的话, Timer会尽量的让任务在一个固定的频率下运行。例如：在上面的例子中，让`secondTask`在1秒钟后，每3秒钟执行一次，但是因为java不是实时的，所以，我们在上个程序中表达的原义并不能够严格执行，例如有时可能资源调度紧张4秒以后才执行下一次，有时候又3.5秒执行。如果我们调用的是`scheduleAtFixedRate`，那么Timer会尽量让你的`secondTask`执行的频率保持在3秒一次。运行上面的程序，假设使用的是`scheduleAtFixedRate`，那么下面的场景就是可能的：1秒钟后，secondTask执行一次，因为系统繁忙，之后的3.5秒后secondTask才得以执行第二次，然后Timer记下了这个延迟，并尝试在下一个任务的时候弥补这个延迟，那么2.5秒后，`secondTask` 将执行的三次。“以固定的频率而不是固定的延迟时间去执行一个任务”就是这个意思。

Timer终止的问题：
默认情况下，只要一个程序的timer线程在运行，那么这个程序就会保持运行。可以通过以下3种方法终止一个timer线程：
（1）调用timer的cancle方法。你可以从程序的任何地方调用此方法，甚至在一个timer task的run方法里；
（2）让timer线程成为一个daemon线程（可以在创建timer时使用new Timer(true)达到这个目地），这样当程序只有daemon线程的时候，它就会自动终止运行； 
（3）调用`System.exit`方法，使整个程序（所有线程）终止。
TimerTask也有cancel方法。
上面所说的“只要一个程序的timer线程在运行，那么这个程序就会保持运行”。那么反过来，如果Timer里的所有TimerTask都执行完了，整个程序会退出吗，经测试答案是否定的，例如上面的测试代码，如果只加第一个TimerTask在Timer中执行：
timer.schedule(new OneTask(1), 5000);// 5秒后启动任务那么5秒以后，其实整个程序还是没有退出，Timer会等待垃圾回收的时候被回收掉然后程序会得以退出，但是多长时间呢？
在TimerTask的run函数执行完以后加上`System.gc()`;就可以了。