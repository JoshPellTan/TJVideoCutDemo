//
//  TJPlayerViewController.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/10.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TJPlayerViewController.h"
#import "TJMediaManager.h"
#import <AVFoundation/AVFoundation.h>
#import "TimeChooseView.h"
#import <Photos/Photos.h>
#import "TJPhotoManager.h"

//添加外部音频的路径宏（后期需要加入外部音频到视频中可以直接传入此音频url，当然名字自己写）
#define AUDIO_URL [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"新歌" ofType:@"mp3"]]


@interface TJPlayerViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;


@property (nonatomic,assign) CGFloat startTime;             //裁剪开始时间点
@property (nonatomic,assign) CGFloat endTime;               //裁剪结束时间点
@property (nonatomic,strong) NSTimer *timer;                //计时器控制预览视频长度
@property (nonatomic,assign) CGFloat playTime;

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIButton *cutBtn;
@property(nonatomic,strong) UIButton *backBtn;

@property (nonatomic,strong) PHFetchResult *collectonResuts;


@end

@implementation TJPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    //设置默认起始时间点
    _startTime = 0;
    _endTime = 15;
    //    [self preViewAction];
    _playTime = 0;
    _timer = [NSTimer timerWithTimeInterval:0.04 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    [self setVideoViewWithUrlPath:_videoUrl.path];
    [self setupUI];
}


-(void)setupUI{
    
    //demo中的按钮
    UIButton *cutBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width-50, 30,40, 40)];
    [cutBtn setImage:[UIImage imageNamed:@"channleGou"] forState:UIControlStateNormal];
    [cutBtn addTarget:self action:@selector(cutVideoAction) forControlEvents:UIControlEventTouchUpInside];
    _cutBtn = cutBtn;
    [self.view addSubview:cutBtn];
    
    UIButton *backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 30, 40, 40)];
    [backBtn setImage:[UIImage imageNamed:@"videoClose"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(cancelOrDoneCutAction) forControlEvents:UIControlEventTouchUpInside];
    _backBtn = backBtn;
    [self.view addSubview:backBtn];
    
    //裁剪操作控制区
    TimeChooseView *chooseView = [[TimeChooseView alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height - 70,self.view.bounds.size.width,50)];
    chooseView.videoURL = self.videoUrl;
    
    __weak typeof (self)weakself = self;
    chooseView.getTimeRange = ^(CGFloat startTime,CGFloat endTime,CGFloat imageTime){
        
        __strong typeof(weakself) strongSelf = weakself;
        
        strongSelf.startTime = startTime;
        strongSelf.endTime = endTime;
        
        [strongSelf jumpToTime:imageTime];
        //实时更新uiimageview的图片会导致编解码过于频繁，退出程序，待解决,解决：直接使用视频图层
        //        strongSelf.imageView.image = [WZMediaManager getCoverImage:strongSelf.videoUrl atTime:imageTime isKeyImage:NO];
        //        if (!strongSelf.imageView.width) {
        //            [strongSelf resetImageViewFrame];
        //        }
        ////        strongSelf.imageView.image = strongSelf.image;
        //
        //
        //        if (strongSelf.imageView.hidden) {
        //            [strongSelf.view bringSubviewToFront:strongSelf.imageView];
        //            strongSelf.imageView.hidden = NO;
        //            [strongSelf pauseVideo];
        //        }
        
    };
    
    chooseView.cutWhenDragEnd = ^{
        
        __strong typeof(weakself) strongSelf = weakself;
        [strongSelf preViewAction];
        
    };
    
    [chooseView setupUI];
    [self.view addSubview:chooseView];
    
}


-(void)setVideoViewWithUrlPath:(NSString *)url{
    
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:url]];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height-20 - 80);
    [self.view.layer addSublayer:self.playerLayer];
    
    [self.player play];
    
    [self.view bringSubviewToFront:_cutBtn];
    [self.view bringSubviewToFront:_backBtn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
}


-(void)timerAction{
    
    _playTime += 0.04;
    if (_endTime-_startTime-_playTime<0.04) {
        [self preViewAction];
        _playTime = 0;
    }
}

-(void)preViewAction{
    
    [_player seekToTime:CMTimeMake(_startTime*30, 30) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [_player play];
    }];
    
}


-(void)cancelOrDoneCutAction{
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }
    [self removeNotification];
    
}


-(void)cutVideoAction{
    
    __block UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height*0.5-10, self.view.bounds.size.width, 20)];
    label.text = @"视频正在剪切";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    [_player pause];
    if (_videoUrl  && self.startTime>=0 && self.endTime>self.startTime) {
        
        TimeRange timeRange = {_startTime,_endTime-_startTime};
        
        __weak typeof(self) weakself = self;
        [TJMediaManager addBackgroundMiusicWithVideoUrlStr:_videoUrl audioUrl:nil andCaptureVideoWithRange:timeRange completion:^{
            NSLog(@"视频裁剪完成");
            
            NSString* videoName = KcutVideoPath;
            NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
            
            [[TJPhotoManager sharedInstance] saveVideoWithPathString:exportPath Success:^(PHAsset *asset) {
                
                __strong typeof(self) strongself = weakself;
                if (strongself.cutDoneBlock) {
                    strongself.cutDoneBlock(asset);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [label removeFromSuperview];
                    [strongself cancelOrDoneCutAction];
                    
                });
                
            } error:^(NSString *error) {
                NSLog(@"错误%@",error);
            }];
        }];
    }
}


-(void)jumpToTime:(CGFloat )time{
    
    [_player pause];
    [_player seekToTime:CMTimeMake(time*30, 30) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
    }];
}

-(void)playbackFinished{
    
    NSLog(@"视频播放完成.");
    // 播放完成后重复播放
    // 跳到剪切开始处
    [_player seekToTime:CMTimeMake(_startTime*30, 30)];
    [_player play];
}


-(void)removeNotification{
    
    [_timer invalidate];
    _timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player = nil;
}

-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

@end
