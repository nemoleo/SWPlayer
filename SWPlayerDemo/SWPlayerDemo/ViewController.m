//
//  ViewController.m
//  SWPlayerDemo
//
//  Created by 李博 on 16/7/4.
//  Copyright © 2016年 Lee. All rights reserved.
//

#import "ViewController.h"
#import "SWPlayer.h"

@interface ViewController ()<SWPlayerDelegate>

@property (nonatomic, strong) SWPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor grayColor]];
    _player = [[SWPlayer alloc] initWithFrame:CGRectMake(0.f, 20.f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame) * 3/4)];
    _player.delegate = self;
    [self.view addSubview:_player];
    
    UIButton *btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnPlay setFrame:CGRectMake(100.f, CGRectGetMaxY(_player.frame) + 30.f, 80.f, 60.f)];
    [btnPlay setTitle:@"播放" forState:UIControlStateNormal];
    [btnPlay setBackgroundColor:[UIColor purpleColor]];
    [btnPlay addTarget:self action:@selector(pressOnPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnPlay];
}

- (void)pressOnPlay:(id)sender
{
    [self.player playWithUrl:[NSURL URLWithString:@"http://baobab.wdjcdn.com/14632011469271463200710319bjeh_22222_x264.mp4"]];
}

#pragma mark SWPlayerDelegate

//播放开始通知
- (void)playbackDidBeginSWPlayer:(SWPlayer *)player
{
    
}

//播放可以继续
- (void)playbackLikelyToKeepUp:(SWPlayer *)player
{
    
}

//播放器恢复播放
- (void)playbackNewLogEntry:(SWPlayer *)player
{
    
}

//播放完成通知
- (void)playbackDidFinish:(SWPlayer *)player
{
    
}

//同步时间变化, 单位:秒
- (void)player:(SWPlayer *)player syncScrubberTime:(NSTimeInterval)time
{
    
}

//播放卡顿时通知
- (void)player:(SWPlayer *)player playBackInterrupt:(NSNotification *)notification
{
    
}

//播放缓冲进度, 单位:秒
- (void)player:(SWPlayer *)player playerBufferTime:(NSTimeInterval)time
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
