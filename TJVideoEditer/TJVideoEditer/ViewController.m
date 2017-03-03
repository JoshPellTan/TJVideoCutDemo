//
//  ViewController.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/10.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "ViewController.h"
#import "TJMediaManager.h"
#import "TJPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

#define AUDIO_URL [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"新歌" ofType:@"mp3"]]

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic,strong)NSURL *videoUrl;
@property(nonatomic,strong)NSURL *audioUrl;
@property(nonatomic,strong)UIImagePickerController *imagePickerController;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupImagePicker];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}
-(void)viewWillDisAppear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

-(void)setupUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *pickVideoBtn = [[UIButton alloc]initWithFrame:CGRectMake(20, 40, 80, 40)];
    pickVideoBtn.backgroundColor = [UIColor lightGrayColor];
    [pickVideoBtn setTitle:@"选择视频" forState:UIControlStateNormal];
    [pickVideoBtn addTarget:self action:@selector(selectVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pickVideoBtn];
    
}

-(void)setupImagePicker{
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    _imagePickerController.allowsEditing = YES;
    
    _audioUrl = AUDIO_URL;
}


- (void)videoPlay{
    
    TJPlayerViewController *pvc = [[TJPlayerViewController alloc] init];
    pvc.videoUrl = _videoUrl;
    [self.navigationController pushViewController:pvc animated:YES];
    
}

- (void)selectVideo {
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self selectImageFromCamera];
        
    }];
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self selectImageFromAlbum];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVc addAction:cameraAction];
    [alertVc addAction:photoAction];
    [alertVc addAction:cancelAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark 从摄像头获取图片或视频
- (void)selectImageFromCamera
{
    //NSLog(@"相机");
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    //录制视频时长，默认10s
    _imagePickerController.videoMaximumDuration = 15;
    //相机类型（拍照、录像...）
    _imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage];
    //视频上传质量
    _imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    //设置摄像头模式（拍照，录制视频）
    _imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

#pragma mark 从相册获取图片或视频
- (void)selectImageFromAlbum
{
    //NSLog(@"相册");
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imagePickerController.mediaTypes = [NSArray arrayWithObjects: @"public.movie", nil];
    [self presentViewController:_imagePickerController animated:YES completion:nil];
    
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        
    }else{
        
        //如果是视频
        NSURL *url = info[UIImagePickerControllerMediaURL];
        
        //播放视频
        _videoUrl = url;
        [self videoPlay];
        
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark 图片保存完毕的回调
- (void) image: (UIImage *) image didFinishSavingWithError:(NSError *) error contextInfo: (void *)contextIn {
    
}

#pragma mark 视频保存完毕的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextIn {
    
    if (error) {
        NSLog(@"保存视频过程中发生错误，错误信息:%@",error.localizedDescription);
    }else{
        NSLog(@"视频保存成功.");
    }
    
}

@end
