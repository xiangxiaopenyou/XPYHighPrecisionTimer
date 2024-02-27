//
//  ViewController.m
//  XPYHighPrecisionTimerTest
//
//  Created by 项林平 on 2022/10/10.
//

#import "ViewController.h"

#import <XPYHighPrecisionTimer/XPYHighPrecisionTimer.h>

@interface ViewController ()

@property (nonatomic, strong) XPYTimer *timer;

@end

@implementation ViewController

static CFAbsoluteTime old_time = 0;
static float total_time = 0.0;
static int frame = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.timer = [[XPYTimer alloc] initWithFPS:30 handler:^{
        CFAbsoluteTime start_time = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime frame_time = start_time - old_time;
        total_time += (frame_time * 1000);
        old_time = start_time;
        frame++;
        if (frame % 100 == 0) {
            float perFrameTime = total_time / 100;
            float fps = 1000 / perFrameTime;
            NSLog(@"⭐️%f", fps);
            total_time = 0;
            frame = 0;
        }
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.timer invalidate];
    });
}

@end
