//
//  TJPlayerViewController.h
//  TJVideoEditer
//
//  Created by TanJian on 17/2/10.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>


@interface TJPlayerViewController : UIViewController

@property (nonatomic, strong) NSURL *videoUrl;
@property(nonatomic,strong) AVPlayerItem *playerItem;

//保存完成后的回调
@property (nonatomic, copy) void (^cutDoneBlock)(PHAsset *);

@end
