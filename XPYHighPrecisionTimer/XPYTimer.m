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

/// 系统心跳（转换因子）
double mach_clock_time(void) {
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);
    double clock = (double) timebase_info.numer / (double)timebase_info.denom;
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

- (instancetype)initWithFPS:(NSInteger)FPS handler:(void (^)(void))handler {
    self = [super init];
    if (self) {
        if (FPS <= 0) {
            FPS = 1;
        }
        self.timerFPS = FPS;
        self.timerClock = handler;
        
        clock_time = mach_clock_time();
        nanoseconds_per_frame = (1.0 / FPS) * NSEC_PER_SEC;
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
    // 设置线程脱离状态属性为 joinable（表示允许线程合并）
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
    // 设置调度优先级最大值
    struct sched_param sched;
    sched.sched_priority = sched_get_priority_max(SCHED_FIFO);
    pthread_attr_setschedparam(&attr, &sched);
    // (__bridge void*)self 作为入口函数的参数
    int result = pthread_create(&pthread, &attr, run_for_thread, (__bridge void *)self);
    if (result != 0) {
        NSLog(@"Create thread failed!");
    }
    // 销毁线程属性
    pthread_attr_destroy(&attr);
}

/// 线程任务入口函数指针
void * run_for_thread(void *arg) {
    XPYTimer *timer = (__bridge XPYTimer *)arg;
    [timer run];
    return NULL;
}

// 终止线程
void exit_thread(void) {
    // 终止线程
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
        // 任务执行周期（系统心跳数）
        uint64_t duration = end_time - begin_time;
        // 任务执行周期精确时间（心跳数 * 转换因子）
        NSTimeInterval duration_time = duration * clock_time;
        if(duration_time < nanoseconds_per_frame) { // 任务执行周期小于限制时间
            // 任务最后期限精确时间点
            NSTimeInterval deadline = end_time + (nanoseconds_per_frame - duration_time) / clock_time;
            // 任务提前精确时间点
//            NSTimeInterval advanced = end_time + (nanoseconds_per_frame - duration_time) / clock_time - (kXPYAdvancedTime * NSEC_PER_SEC / clock_time);
//            // 等待
//            mach_wait_until(advanced);
            while (mach_absolute_time() < deadline) {
            }
        }
    }
    exit_thread();
}

- (void)invalidate {
    if (running) {
        running = NO;
        // 等待线程结束，释放资源，如果已经结束会立即返回
        void *result;
        pthread_join(pthread, &result);
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
