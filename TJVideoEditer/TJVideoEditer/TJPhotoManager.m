//
//  TJPhotoManager.m
//  TJVideoEditer
//
//  Created by TanJian on 17/3/3.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TJPhotoManager.h"

@interface TJPhotoManager ()<PHPhotoLibraryChangeObserver>

@property (nonatomic,strong) NSArray <PHFetchResult *>*fetchResults;

@property (nonatomic,strong) NSArray *mediaTypes;

//相册集合
@property (nonatomic,strong) PHFetchResult *collectonResuts;

@property (nonatomic,copy) void(^completionHandler)(PHAsset *);

@end

@implementation TJPhotoManager

+ (instancetype)sharedInstance {
    static TJPhotoManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TJPhotoManager new];
    });
    return instance;
}

- (id)initWithMediaTypes:(NSArray *)mediaTypes
{
    self = [super init];
    if (self) {
        self.mediaTypes = mediaTypes;
    }
    return self;
}

- (PHFetchResult *)assetsInAssetCollection:(PHAssetCollection *)album{
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.mediaTypes];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    return [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)album options:options];
}

//手机中的微籽相册
+(void)getDefaultAlbumSuccess:(void(^)())completionHandler error:(void(^)(NSString *))error{
    
    
    NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    
    PHFetchResult<PHAssetCollection *> *collections =  [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHAssetCollection * createCollection = nil; // 最终要获取的自己创建的相册
    
    for (PHAssetCollection * collection in collections) {
        
        if ([collection.localizedTitle isEqualToString:title]) {    // 如果有自己要创建的相册
            
            createCollection = collection;
            
            break;
            
        }
        
    }
    
    if (createCollection == nil) {  // 如果没有自己要创建的相册
        
        // 创建自己要创建的相册
        
        NSError * error1 = nil;
        
        __block NSString * createCollectionID = nil;
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            
            NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
            
            createCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
            
        } error:&error1];
        
        
        if (error1) {
            
            NSLog(@"创建相册失败...");
            
        }
        
        // 创建相册之后我们还要获取此相册  因为我们要往进存储相片
        
        createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createCollectionID] options:nil].firstObject;
        
    }
    
    if (createCollection != nil) {
        completionHandler();
    }else{
        error(@"创建相册失败...");
    }
    
}

- (void)saveVideoWithPathString:(NSString *)path Success:(void(^)(PHAsset *))completionHandler error:(void(^)(NSString *))error{
    
    self.completionHandler = completionHandler;
    
    [TJPhotoManager getDefaultAlbumSuccess:^{
        
        __block NSString *localIdentifier = @"";
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        //首先获取系统相册的集合
        //            _collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
        _collectonResuts = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        
        PHAssetCollection *assetCollection = _collectonResuts[0];
        
        NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
        if (![assetCollection.localizedTitle isEqualToString:title] ) {
            
            for (PHAssetCollection *collection in _collectonResuts) {
                
                if ([collection.localizedTitle isEqualToString:title]) {
                    assetCollection = collection;
                    break;
                    
                }
            }
            
        }
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //请求创建一个Asset
            PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:path]];
            //请求编辑相册
            PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            //为Asset创建一个占位符，放到相册编辑请求中
            PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
            //相册中添加视频
            [collectonRequest addAssets:@[placeHolder]];
            
            localIdentifier = placeHolder.localIdentifier;
            
        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                //                NSLog(@"保存视频成功!");
                return ;
            } else {
                NSLog(@"保存视频失败:%@", error);
            }
        }];
        
    } error:^(NSString *errorInfo){
        
        error(errorInfo);
    }];
}


//PHPhotoLibraryChangeObserver
-(void)photoLibraryDidChange:(PHChange *)changeInstance{
    
    NSLog(@"保存视频成功!");
    
    PHFetchResultChangeDetails *resultChange = [changeInstance changeDetailsForFetchResult:_collectonResuts];
    
    NSArray *arr = resultChange.changedObjects;
    PHAssetCollection *coll = arr[0];
    
    TJPhotoManager *manager = [[TJPhotoManager alloc]initWithMediaTypes:@[@(PHAssetMediaTypeVideo)]];
    PHFetchResult *fetchResult = [manager assetsInAssetCollection:coll];
    PHAsset *asset = fetchResult[0];
    
    
    if (self.completionHandler) {
        self.completionHandler(asset);
    }
    
}

@end
