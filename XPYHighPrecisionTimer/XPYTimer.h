//
//  XPYTimer.h
//  XPYHighPrecisionTimer
//
//  Created by 项林平 on 2022/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XPYTimer : NSObject

/// 初始化方法
/// - Parameters:
///   - FPS: 频率
///   - handler: 回调
- (instancetype)initWithFPS:(NSInteger)FPS clockHandler:(nullable void (^)(void))handler;

- (void)invalidate;

#pragma mark - Unavailable methods

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
