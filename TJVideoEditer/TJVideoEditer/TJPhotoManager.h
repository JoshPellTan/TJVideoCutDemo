//
//  TJPhotoManager.h
//  TJVideoEditer
//
//  Created by TanJian on 17/3/3.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface TJPhotoManager : NSObject


#pragma mark 不使用photokit选择视频的方法1,2,6
+ (instancetype)sharedInstance;
/**
 根据传入的视频路径保存成一个asset媒体
 
 */
- (void)saveVideoWithPathString:(NSString *)path Success:(void(^)(PHAsset *))completionHandler error:(void(^)(NSString *))error;



@end
