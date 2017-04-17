//
//  TJMediaManager.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/10.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TJMediaManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation TJMediaManager

+ (void)addBackgroundMiusicWithVideoUrlStr:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl andCaptureVideoWithRange:(TimeRange)videoRange completion:(void(^)(void))completionHandle {
    
    //AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVURLAsset* audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //CMTimeRangeMake(start, duration),start起始时间，duration时长，都是CMTime类型
    //CMTimeMake(int64_t value, int32_t timescale)，返回CMTime，value视频的一个总帧数，timescale是指每秒视频播放的帧数，视频播放速率，（value / timescale）才是视频实际的秒数时长，timescale一般情况下不改变，截取视频长度通过改变value的值
    //CMTimeMakeWithSeconds(Float64 seconds, int32_t preferredTimeScale)，返回CMTime，seconds截取时长（单位秒），preferredTimeScale每秒帧数
    
    //开始位置startTime
    CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, videoAsset.duration.timescale);
    //截取长度videoDuration
    CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, videoAsset.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
    
    //视频采集compositionVideoTrack
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
#warning 避免数组越界 tracksWithMediaType 找不到对应的文件时候返回空数组
    //TimeRange截取的范围长度
    //ofTrack来源
    //atTime插放在视频的时间位置
    [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:([videoAsset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero error:nil];
    
    //下面3行代码用于保证后面输出的视频方向跟原视频方向一致
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoUrl];
    AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    NSLog(@"帧率：%f，比特率：%f", assetVideoTrack.nominalFrameRate,assetVideoTrack.estimatedDataRate);
    
    
    //视频声音采集(也可不执行这段代码不采集视频音轨，合并后的视频文件将没有视频原来的声音)
    AVMutableCompositionTrack *compositionVoiceTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVoiceTrack insertTimeRange:videoTimeRange ofTrack:([videoAsset tracksWithMediaType:AVMediaTypeAudio].count>0)?[videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject:nil atTime:kCMTimeZero error:nil];
    
    
    //外部音频采集，最后合成到原视频，与原视频的音频不冲突
    //声音长度截取范围==视频长度
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, videoDuration);
    
    if (audioUrl) {
        //音频采集compositionCommentaryTrack
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) ? [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject : nil atTime:kCMTimeZero error:nil];
    }
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:KcutVideoPath];
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    
    //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
    assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
    //    NSArray *fileTypes = assetExportSession.
    
    assetExportSession.outputURL = outPutUrl;
    NSLog(@"^^^^^^^^^%ld",[self degressFromVideoFileWithURL:outPutUrl]);
    
    //输出文件是否网络优化
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        completionHandle();
    }];
}

+ (CGFloat)getMediaDurationWithMediaUrl:(NSString *)mediaUrlStr {
    
    NSURL *mediaUrl = [NSURL URLWithString:mediaUrlStr];
    AVURLAsset *mediaAsset = [[AVURLAsset alloc] initWithURL:mediaUrl options:nil];
    CMTime duration = mediaAsset.duration;
    
    return duration.value / duration.timescale;
}

+ (NSString *)getMediaFilePath {
    
    return [NSTemporaryDirectory() stringByAppendingPathComponent:KcutVideoPath];
    
}

#pragma 获取想要时间的帧视频图片
+(UIImage *)getCoverImage:(NSURL *)outMovieURL atTime:(CGFloat)time isKeyImage:(BOOL)isKeyImage{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:outMovieURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    __block CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    
    //  通常开发者认为时间的呈现格式应该是浮点数据，我们一般使用NSTimeInterval，实际上它是简单的双精度double类型，只是typedef了一下，但是由于浮点型数据计算很容易导致精度的丢失，在一些要求高精度的应用场景显然不适合，于是苹果在Core Media框架中定义了CMTime数据类型作为时间的格式,
    //  typedef struct{
    //
    //  CMTimeValue    value;
    //  CMTimeScale    timescale;
    //  CMTimeFlags    flags;
    //  CMTimeEpoch    epoch;
    //  } CMTime;
    //  显然，CMTime定义是一个C语言的结构体，CMTime是以分数的形式表示时间，value表示分子，timescale表示分母，flags是位掩码，表示时间的指定状态。CMTimeMake(3, 1)结果为3。
    
    
    //tips:下面7行代码控制取图的时间点是否为关键帧，系统为了性能是默认取关键帧图片的
    CMTime myTime = CMTimeMake(time, 1);
    if (!isKeyImage) {
        assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        CMTime duration = asset.duration;
        myTime = CMTimeMake(time*30,30);
    }
    
    
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:myTime actualTime:NULL error:nil];
    
    if (!thumbnailImageRef){
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    CGImageRelease(thumbnailImageRef);
    //    return [UIImage imageNamed:@"icomImg"];
    return thumbnailImage;
    
}


+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

//获取视频时长
+(CGFloat)getVideoTimeWithURL:(NSURL *)videoURL{
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    CGFloat totalSecond = urlAsset.duration.value*1.0f / urlAsset.duration.timescale;
    
    return totalSecond;
}


@end
