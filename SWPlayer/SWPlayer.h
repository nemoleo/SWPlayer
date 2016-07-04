//
//  SWPlayer.h
//  SWPlayer
//
//  Created by 李博 on 16/7/4.
//  Copyright © 2016年 Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PlayerStatus) {
    PlayerUnknown = 10,
    PlayerPlaying = 11,
    PlayerPause = 12,
    PlayerStop = 13,
    PlayerFail = 14,
};

@class SWPlayer;

@protocol SWPlayerDelegate <NSObject>

@optional

//播放开始通知
- (void)playbackDidBeginSWPlayer:(SWPlayer *)player ;

//播放可以继续
- (void)playbackLikelyToKeepUp:(SWPlayer *)player;

//播放器恢复播放
- (void)playbackNewLogEntry:(SWPlayer *)player;
//播放完成通知
- (void)playbackDidFinish:(SWPlayer *)player;

//同步时间变化, 单位:秒
- (void)player:(SWPlayer *)player syncScrubberTime:(NSTimeInterval)time;

//播放卡顿时通知
- (void)player:(SWPlayer *)player playBackInterrupt:(NSNotification *)notification;

//播放缓冲进度, 单位:秒
- (void)player:(SWPlayer *)player playerBufferTime:(NSTimeInterval)time;

@end

@interface SWPlayer : UIView

//播放状态
@property (nonatomic, assign, readonly)PlayerStatus status;

//播放代理
@property (nonatomic, weak)id<SWPlayerDelegate>delegate;

//目前播放时间
@property (nonatomic, assign,readonly)NSTimeInterval currentTime;

//总时长
@property (nonatomic, assign,readonly)NSTimeInterval duration;

//播放URL
- (void)playWithUrl:(NSURL *)url;

//播放控制
- (void)play;
- (void)pause;
- (void)stop;

//seek
- (void)seekToTime:(NSTimeInterval)time;

//seek
- (void)seekToTime:(NSTimeInterval)time  status:(PlayerStatus)status;

@end
