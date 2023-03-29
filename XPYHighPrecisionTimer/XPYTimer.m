//
//  XPYTimer.m
//  XPYHighPrecisionTimer
//
//  Created by 项林平 on 2022/10/10.
//

#import "XPYTimer.h"

#include <mach/mach.h>
#include <mach/mach_time.h>
#include <pthread.h>

// 默认线程循环提前时间
static const double kXPYAdvancedTime = 0.01;

/// 系统心跳，返回单位秒
double mach_clock_time(void) {
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);
    double clock = 1e-9 * ((double) timebase_info.numer / (double)timebase_info.denom);
    return clock;
}

@interface XPYTimer ()

@property (nonatomic, copy) void (^timerClock)(void);

@property (nonatomic, assign) NSInteger timerFPS;

@end

@implementation XPYTimer {
    pthread_t pthread;
    double clock_time;
    BOOL running;
    // 每帧限制时间，单位纳秒，根据限制帧率计算
    double nanoseconds_per_frame;
    
    uint64_t lastFrameTime;
}

- (instancetype)initWithFPS:(NSInteger)FPS clockHandler:(void (^)(void))handler {
    self = [super init];
    if (self) {
        if (FPS <= 0) {
            FPS = 1;
        }
        self.timerFPS = FPS;
        self.timerClock = handler;
        
        clock_time = mach_clock_time();
        nanoseconds_per_frame = 1.0/FPS/clock_time;
        running = YES;
        
        [self createThread];
    }
    return self;
}

/// 线程创建
- (void)createThread {
    // 声明线程属性
    pthread_attr_t attr;
    // 初始化线程属性
    pthread_attr_init(&attr);
    // 设置调度策略为先进先出
    pthread_attr_setschedpolicy(&attr, SCHED_FIFO);
    // 设置线程状态为joinable
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
    // 设置调度优先级最大值
    struct sched_param sched;
    sched.sched_priority = sched_get_priority_max(SCHED_FIFO);
    pthread_attr_setschedparam(&attr, &sched);
    int result = pthread_create(&pthread, &attr, (void *)run_for_thread, (__bridge void *)self);
    if (result != 0) {
        NSLog(@"Create thread failed!");
    }
    // 销毁线程属性
    pthread_attr_destroy(&attr);
}

void run_for_thread(void *arg) {
    XPYTimer *timer = (__bridge XPYTimer *)arg;
    [timer run];
    pthread_exit(NULL);
}

void thread_signal(int signal) {}

- (void)run {
    signal(SIGALRM, thread_signal);
    while (running) {
        // 任务开始时间
        uint64_t begin_time = mach_absolute_time();
        // 执行任务
        if (self.timerClock) {
            self.timerClock();
        }
        // 任务结束时间
        uint64_t end_time = mach_absolute_time();
        // 任务执行周期
        uint64_t duration = end_time - begin_time;
        if(duration < nanoseconds_per_frame) { // 任务执行时间小于限制时间
            // 计算需要等待的最终精确时间点
            NSTimeInterval deadline_interval = (end_time + nanoseconds_per_frame - duration) * clock_time;
            // 提前精确时间点
            NSTimeInterval wait_time_interval = deadline_interval - kXPYAdvancedTime;
            // 等待
            mach_wait_until(wait_time_interval / clock_time);
            if (mach_absolute_time() < deadline_interval / clock_time) { // 当前还没到最终时间
                // 计算当前时间点与最终时间点差值
                uint64_t deadline_time = deadline_interval / clock_time;
                uint64_t current_time = mach_absolute_time();
                uint64_t difference_time = deadline_time - current_time;
                double difference_nano_time = difference_time * clock_time / 1e-9;
                struct timespec rqtp;
                rqtp.tv_sec = difference_nano_time * 1.0e-9;
                rqtp.tv_nsec = difference_nano_time;
                // sleep
                if (nanosleep(&rqtp, NULL) == -1) {
                    NSLog(@"Error");
                }
            }
            
//            while (mach_absolute_time() < deadline_interval / clock_time && mach_absolute_time() > wait_time_interval / clock_time) {
//                // 循环等待
//            }
        }
    }
}

- (void)invalidate {
    if (running) {
        running = NO;
        // 挂起等待线程结束，释放资源
        void *result;
        pthread_join(pthread, &result);
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
