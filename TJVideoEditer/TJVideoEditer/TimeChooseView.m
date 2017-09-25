//
//  TimeChooseView.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/13.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TimeChooseView.h"
#import <AVFoundation/AVFoundation.h>
#import "TJMediaManager.h"


#define KendTimeButtonWidth self.bounds.size.width*0.5/3
#define KimageCount 15
#define KtotalTimeForSelf 15   //本页全长代表的视频时间



@interface WZScrollView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGRect *rect;


-(void)drawImage:(UIImage *)image inRect:(CGRect)rect;

@end

@implementation WZScrollView

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    [_image drawInRect:rect];
}

-(void)drawImage:(UIImage *)image inRect:(CGRect)rect{
    
    _image = image;
    _rect = &rect;
    
    [self setNeedsDisplayInRect:rect];
}

@end

typedef enum {
    
    imageTypeStart,
    imageTypeEnd,
    
}imageType;


@interface TimeChooseView ()<UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;

@property (nonatomic,strong) UIImageView *startView;
@property (nonatomic,strong) UIImageView *endView;
@property (nonatomic,strong) UIView *topLine;
@property (nonatomic,strong) UIView *bottomLine;

@property (nonatomic,assign) CGFloat startTime;
@property (nonatomic,assign) CGFloat endTime;

@property (nonatomic,assign) CGFloat totalTime;

//正在操作开始或者结束指示器的类型
@property (nonatomic,assign) imageType chooseType;

@end


@implementation TimeChooseView

-(void)setupUI{
    
    
    _totalTime = [TJMediaManager getVideoTimeWithURL:self.videoURL];
    _startTime = 0;
    _endTime = KtotalTimeForSelf;
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.bounces = NO;
    [self addSubview:_scrollView];
    
    //缩略图宽度
    UIImage *tempImage = [TJMediaManager getCoverImage:self.videoURL atTime:0 isKeyImage:NO];
    CGFloat width = tempImage.size.width*self.bounds.size.height/tempImage.size.height;
    
    //展示图片能看到的宽度
    CGFloat imageShowW = self.bounds.size.width*1.0f/KimageCount;
    
    if (width<imageShowW) {
        imageShowW = width;
    }
    
    //当前界面取KimageCount张图片展示15秒视频（取15张）
    CGFloat timeUnit = KtotalTimeForSelf*1.0f/KimageCount;
    NSInteger count = _totalTime/timeUnit;
    
    _scrollView.contentSize = CGSizeMake(_totalTime*imageShowW, self.bounds.size.height);
    
    
    WZScrollView *view = [[WZScrollView alloc]initWithFrame:CGRectMake(0,0,_totalTime*imageShowW, self.bounds.size.height)];
    [_scrollView addSubview:view];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSInteger i = 0; i<count; i++) {
            
            
            UIImage *image = [TJMediaManager getCoverImage:self.videoURL atTime:timeUnit*i isKeyImage:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [view drawImage:image inRect:CGRectMake(i*imageShowW, 0, width, self.bounds.size.height)];
                
            });
            
            //循环多次创建uiimageview会导致内存暴涨，引起崩溃,解决：使用绘制把图片绘制到scrollview
            //            UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(i*imageShowW, 0, width, self.height)];
            //            imageView.image = image;
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                [_scrollView addSubview:imageView];
            //            });
        }
    });
    
    //添加裁剪范围框
    self.startView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, KendTimeButtonWidth, self.bounds.size.height)];
    _startView.image = [UIImage imageNamed:@"left"];
    _startView.tag = 99;
    UIPanGestureRecognizer * recognizer1 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    recognizer1.maximumNumberOfTouches = 1;
    recognizer1.minimumNumberOfTouches = 1;
    [_startView addGestureRecognizer:recognizer1];
    [self addSubview:_startView];
    self.startView.userInteractionEnabled = YES;
    
    self.endView = [[UIImageView alloc]initWithFrame:CGRectMake(self.bounds.size.width-KendTimeButtonWidth, 0, KendTimeButtonWidth, self.bounds.size.height)];
    _endView.image = [UIImage imageNamed:@"right"];
    _endView.tag = 100;
    UIPanGestureRecognizer * recognizer2 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    recognizer2.maximumNumberOfTouches = 1;
    recognizer2.minimumNumberOfTouches = 1;
    [_endView addGestureRecognizer:recognizer2];
    [self addSubview:_endView];
    self.endView.userInteractionEnabled = YES;
    
    self.topLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 3)];
    _topLine.backgroundColor = [UIColor whiteColor];
    [self addSubview:_topLine];
    
    self.bottomLine = [[UIView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-3,self.topLine.frame.size.width, 3)];
    _bottomLine.backgroundColor = [UIColor whiteColor];
    [self addSubview:_bottomLine];
    
}


//-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

//    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
//    NSArray *touchViews = [allTouches allObjects];
//    UITouch *touch = touchViews.firstObject;
//    CGPoint point = [touch locationInView:self];
//
//    if (point.x >= self.endView.x-20) {
//        self.chooseType = imageTypeEnd;
//
//    }else if(point.x <= self.startView.x + self.startView.width ){
//
//        self.chooseType = imageTypeStart;
//    }else{
//        return;
//    }
//
//    //取startView的x到endView的maxX为截取视频距离，下面计算以此为标准
//    switch (self.chooseType) {
//        case imageTypeEnd:
//        {
//            self.endView.frame = CGRectMake(point.x-KendTimeButtonWidth*0.5, 0,KendTimeButtonWidth, self.bounds.size.height);
//
//            if (self.endView.frame.origin.x+KendTimeButtonWidth-self.startView.frame.origin.x<=self.bounds.size.width/3.0f) {
//
//                self.endView.frame = CGRectMake(self.bounds.size.width*1/3.0f-KendTimeButtonWidth+self.startView.frame.origin.x, 0, KendTimeButtonWidth, self.bounds.size.height);
//            }else if(self.endView.frame.origin.x>self.bounds.size.width-KendTimeButtonWidth){
//
//                self.endView.frame = CGRectMake(self.bounds.size.width-KendTimeButtonWidth, 0, KendTimeButtonWidth, self.bounds.size.height);
//            }
//
//        }
//            break;
//        case imageTypeStart:
//        {
//            self.startView.frame = CGRectMake(point.x-KendTimeButtonWidth*0.5, 0,KendTimeButtonWidth, self.bounds.size.height);
//
//            if (self.startView.x <= 0) {
//
//                self.startView.frame = CGRectMake(0, 0, KendTimeButtonWidth, self.height);
//
//            }else if(self.startView.x >= self.endView.x+KendTimeButtonWidth-self.width/3.0f){
//
//                self.startView.frame = CGRectMake(self.endView.x+KendTimeButtonWidth-self.bounds.size.width/3.0f, 0, KendTimeButtonWidth, self.bounds.size.height);
//            }
//        }
//            break;
//        default:
//            break;
//    }
//
//    self.topLine.frame = CGRectMake(self.startView.frame.origin.x, 0, self.endView.frame.origin.x-self.startView.frame.origin.x + KendTimeButtonWidth, 3);
//    self.bottomLine.frame = CGRectMake(self.topLine.frame.origin.x, self.bounds.size.height-3, self.topLine.frame.size.width, 3);
//
//    //计算裁剪时间
//    [self calculateForTimeNodes];
//
//}



-(void)panAction:(UIPanGestureRecognizer *)panGR{
    
    UIView *view = panGR.view;
    CGPoint P = [panGR translationInView:self.superview];
    CGPoint oldOrigin = view.frame.origin;
    
    switch (view.tag) {
        case 99:
        {
            _chooseType = imageTypeStart;
            if(oldOrigin.x+P.x <= CGRectGetMaxX(self.endView.frame)-self.bounds.size.width/3.0f && oldOrigin.x+P.x>=0){
                
                view.frame = CGRectMake(oldOrigin.x+P.x, 0,KendTimeButtonWidth, self.bounds.size.height);
            }
        }
            break;
        case 100:
        {
            _chooseType = imageTypeEnd;
            if (oldOrigin.x+P.x+KendTimeButtonWidth-self.startView.frame.origin.x>=self.bounds.size.width/3.0f && oldOrigin.x+P.x+KendTimeButtonWidth<=self.bounds.size.width) {
                
                view.frame = CGRectMake(oldOrigin.x+P.x, 0,KendTimeButtonWidth, self.bounds.size.height);
            }
        }
            
            break;
        default:
            break;
    }
    
    self.topLine.frame = CGRectMake(self.startView.frame.origin.x, 0, self.endView.frame.origin.x-self.startView.frame.origin.x + KendTimeButtonWidth, 3);
    self.bottomLine.frame = CGRectMake(self.topLine.frame.origin.x, self.bounds.size.height-3, self.topLine.frame.size.width, 3);
    
    if(panGR.state == UIGestureRecognizerStateChanged)
    {
        [panGR setTranslation:CGPointZero inView:self.superview];
        
    }
    //实时计算裁剪时间
    [self calculateForTimeNodes];
    
    if (panGR.state == UIGestureRecognizerStateEnded) {
        if (self.cutWhenDragEnd) {
            self.cutWhenDragEnd();
        }
    }
}


//计算开始结束时间点
-(void)calculateForTimeNodes{
    
    CGPoint offset = _scrollView.contentOffset;
    
    //可滚动范围分摊滚动范围代表的剩下时间
    _startTime = (offset.x+self.startView.frame.origin.x)*KtotalTimeForSelf*1.0f/self.bounds.size.width;
    _endTime = (offset.x + self.endView.frame.origin.x + KendTimeButtonWidth) * KtotalTimeForSelf * 1.0f/self.bounds.size.width;
    
    //预览时间点
    CGFloat imageTime = _startTime;
    if (_chooseType == imageTypeEnd) {
        imageTime = _endTime;
    }
    
    
    if (self.getTimeRange) {
        self.getTimeRange(_startTime,_endTime,imageTime);
    }
}

#pragma mark scrollview代理

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    _chooseType = imageTypeStart;
    [self calculateForTimeNodes];
    NSLog(@"%f",scrollView.contentOffset.x);
    
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{

    if (self.cutWhenDragEnd) {
        self.cutWhenDragEnd();
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    if (self.cutWhenDragEnd) {
        self.cutWhenDragEnd();
    }

}


@end
