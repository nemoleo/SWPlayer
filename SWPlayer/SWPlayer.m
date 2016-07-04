//
//  SWPlayer.m
//  SWPlayer
//
//  Created by 李博 on 16/7/4.
//  Copyright © 2016年 Lee. All rights reserved.
//

#import "SWPlayer.h"
#import <AVFoundation/AVFoundation.h>

#ifdef DEBUG

#define SWPlayerLog(...) NSLog(__VA_ARGS__);
#define SWPlayerLog_METHOD NSLog(@"%s", __func__);

#else

#define SWPlayerLog(...);
#define SWPlayerLog_METHOD

#endif

@interface SWPlayer ()

@property (nonatomic, strong)AVPlayer *player;//AVPlayer播放器

@property (nonatomic, strong)AVPlayerLayer *playerLayer;//播放器视图层

@end

@implementation SWPlayer
{
    id _playerTimeObserver;//计时器
    BOOL _observerIsRegistered;//记录播放器注册
    BOOL _playStart;//开始播放
    BOOL _enterToBackGround;//是否进入到后台
    PlayerStatus _seekStatus;//记录seek之前的状态
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor blackColor];
        self.status = PlayerUnknown;
        _seekStatus = PlayerUnknown;
        _enterToBackGround = NO;
    }
    return self;
}

- (void)dealloc
{
    SWPlayerLog_METHOD
    [self removeObserverForPlayer];
}

- (void)layoutSubviews
{
    self.playerLayer.frame = self.bounds;
}

//播放url
- (void)playWithUrl:(NSURL *)url
{
    //播放器从后台到前台需要重新播放情况 此时忽略播放器的play
    _enterToBackGround = NO;
    //播放前清空注册信息
    [self removeObserverForPlayer];
    _playStart = NO;
    
    //创建AVPlayerItem
    AVAsset *playerAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: [NSNumber numberWithBool:NO]}];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playerAsset];
    
    //创建（替换）AVPlayerItem
    if ([self.player currentItem]) {
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    } else {
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    
    //创建playerLayer图层
    if (!self.playerLayer) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        self.playerLayer.frame = self.bounds;
        [self.layer addSublayer:_playerLayer];
    }
    
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    //注册播放通知
    [self registerObserverForPlayer];
}

- (void)setStatus:(PlayerStatus)status
{
    _status = status;
}

#pragma mark - 播放控制

- (void)play
{
    SWPlayerLog(@"SWPlayer:播放开始");
    [self.player play];
    self.status = PlayerPlaying;
}

- (void)pause
{
    SWPlayerLog(@"SWPlayer:播放暂停");
    [self.player pause];
    self.status = PlayerPause;
}

- (void)stop
{
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    [self removeObserverForPlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

#pragma mark - KVO注册、释放、触发事件

//注册观察者
- (void)registerObserverForPlayer
{
    if (_observerIsRegistered) {
        //已注册不进行注册
        return;
    }
    
    //监视播放速率rate
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    //监视播放状态status
    [[self.player currentItem] addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监视缓冲进度loadedTimeRanges
    [[self.player currentItem] addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监视缓冲是否完成playbackBufferFull
    [[self.player currentItem] addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    //监视继续播放状态playbackLikelyToKeepUp
    [[self.player currentItem] addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //监视播放器卡顿playbackBufferEmpty
    [[self.player currentItem] addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //监视播放器卡顿
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackInterrupt:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    //监视播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //计时监视器
    __weak typeof(self) weakSelf = self;
    _playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:dispatch_get_global_queue(0, 0) usingBlock:^(CMTime time) {
        
        [weakSelf syncScrubberWithCMTime:time];
    }];
    _observerIsRegistered = YES;
}

//移除观察者
- (void)removeObserverForPlayer
{
    if (!_observerIsRegistered) {
        //未注册测不去掉
        return;
    }
    //释放rate
    [self.player removeObserver:self forKeyPath:@"rate"];
    //释放status
    [[self.player currentItem] removeObserver:self forKeyPath:@"status"];
    //释放loadedTimeRanges
    [[self.player currentItem] removeObserver:self forKeyPath:@"loadedTimeRanges"];
    //释放playbackBufferFull
    [[self.player currentItem] removeObserver:self forKeyPath:@"playbackBufferFull"];
    //释放playbackLikelyToKeepUp
    [[self.player currentItem] removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    //释放playbackBufferEmpty
    [[self.player currentItem] removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    //释放NSNotificationCenter观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //释放计时器监视
    if (_playerTimeObserver) {
        [self.player removeTimeObserver:_playerTimeObserver];
    }
    _observerIsRegistered = NO;
}

//计时器同步方法
- (void)syncScrubberWithCMTime:(CMTime)time
{
    NSTimeInterval synTime =  CMTimeGetSeconds(time);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (_delegate && [_delegate respondsToSelector:@selector(player:syncScrubberTime:)])
        {
            [_delegate player:strongSelf syncScrubberTime:synTime];
        }
    });
}

//播放完成时调用
- (void)playBackFinished:(NSNotification *)notification
{
    SWPlayerLog(@"SWPlayer:播放完成");
    [self stop];
    if (_delegate && [_delegate respondsToSelector:@selector(playbackDidFinish:)]) {
        [_delegate playbackDidFinish:self];
    }
}

//播放卡顿时调用
- (void)playBackInterrupt:(NSNotification *)notification
{
    SWPlayerLog(@"SWPlayer:播放卡顿");
    if (_delegate && [_delegate respondsToSelector:@selector(player:playBackInterrupt:)]) {
        [_delegate player:self playBackInterrupt:notification];
    }
}

//进入后台
- (void)appEnterBackground:(NSNotification *)notification
{
    SWPlayerLog(@"SWPlayer:进入后台")
    [self pause];
    self.status = PlayerPause;
    _enterToBackGround = YES;
}

//进入前台
- (void)appEnterForeground:(NSNotification *)notification
{
    if (_enterToBackGround) {
        SWPlayerLog(@"SWPlayer:返回前台")
        [self play];
        self.status = PlayerPlaying;
        _enterToBackGround = NO;
    }
}

//KVO监视事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    //status
    if ([keyPath isEqualToString:@"status"]) {
        
        switch (self.player.status) {
            case AVPlayerStatusUnknown:
                
                SWPlayerLog(@"SWPlayer:播放状态未知");
                self.status = PlayerUnknown;
                break;
            case AVPlayerStatusReadyToPlay: {
                
                SWPlayerLog(@"SWPlayer:播放就绪");
                self.status = PlayerPlaying;
                if (!_playStart) {
                    if (_delegate && [_delegate respondsToSelector:@selector(playbackDidBeginSWPlayer:)]) {
                        [_delegate playbackDidBeginSWPlayer:self];
                    }
                    _playStart = YES;
                }
                
                //如果seek播放，则保持seek前的播放状态
                if (_seekStatus == PlayerPause) {
                    [self pause];
                    _seekStatus = PlayerUnknown;
                }else {
                    [self play];
                    _seekStatus = PlayerUnknown;
                }
            }
                break;
            case AVPlayerStatusFailed:
                self.status = PlayerFail;
                SWPlayerLog(@"SWPlayer:播放失败");
                break;
            default:
                break;
        }
    }
    
    //rate
    if ([keyPath isEqualToString:@"rate"]) {
        
    }
    
    //loadedTimeRanges
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(player:playerBufferTime:)]) {
            [_delegate player:self playerBufferTime:[self availableDuration]];
        }
    }
    
    //playbackBufferEmpty
    if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        //        self.status = PlayerInterrupt;
    }
    
    //playbackBufferFull
    if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        
        SWPlayerLog(@"SWPlayer:缓冲完成");
    }
    
    //playbackLikelyToKeepUp
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        SWPlayerLog(@"SWPlayer:可以继续");
        if (_delegate && [_delegate respondsToSelector:@selector(playbackLikelyToKeepUp:)]) {
            [_delegate playbackLikelyToKeepUp:self];
        }
        if (_seekStatus == PlayerPause) {
            self.status = PlayerPause;
            [self pause];
            _seekStatus = PlayerUnknown;
        }else if (_seekStatus == PlayerPlaying) {
            self.status = PlayerPlaying;
            [self play];
            _seekStatus = PlayerUnknown;
        }
    }
}


#pragma mark - private

//缓冲总时长
- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    if (loadedTimeRanges && loadedTimeRanges.count > 0) {
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
        return result;
    }
    return 0.f;
}

//seek
- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time status:self.status];
}

//seek
- (void)seekToTime:(NSTimeInterval)time status:(PlayerStatus)status
{
    _seekStatus = status;
    if (time >= [self duration] * 0.999999) {
        //直接seek到duration时会seek失败
        [self.player seekToTime:CMTimeMake([self duration] * 0.999999, 1)];
    }else {
        [self.player seekToTime:CMTimeMake(time, 1)];
        
    }
}

//当前时间
- (NSTimeInterval)currentTime
{
    return CMTimeGetSeconds([_player currentTime]);
}

//总时间
- (NSTimeInterval)duration
{
    AVPlayerItem *playerItem = [_player currentItem];
    if ([playerItem status] == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds([[playerItem asset] duration]);
    } else {
        return 0.f;
    }
}

@end
