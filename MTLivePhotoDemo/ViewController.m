//
//  ViewController.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/9/13.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <PhotosUI/PhotosUI.h>
#import "MTJPEG.h"
#import "MTMov.h"
#import "MTVideoPickerViewController.h"
#import "MTCameraView.h"
#import "Masonry.h"
#import "MTLivePhotoCameraButton.h"
#import "MTLivePhotoFilter.h"

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet PHLivePhotoView *livePhotoView;
@property (nonatomic, retain)NSString *cashDictionary;
@property (nonatomic, retain)MTLivePhotoCameraButton *randomFilterButton;
@property (nonatomic, retain)MTLivePhotoCameraButton *saveToAlbumButton;
@property (nonatomic, retain)MTLivePhotoCameraButton *cancelPostFilterButton;
@property (nonatomic, retain)NSURL *originalMovURL;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MTAudioVideoFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MTRecordFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MTConvertiOS10LivePhoto" object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNotification];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cashDictionary = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
    
    [self initButton];
    
}
- (void)initNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioFinished) name:@"MTAudioVideoFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlerRecordFinished:) name:@"MTRecordFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLivePhotoOfiOS10:) name:@"MTConvertiOS10LivePhoto" object:nil];
}

- (void)initButton
{
    self.randomFilterButton = [MTLivePhotoCameraButton buttonWithTitle:@"随机后期滤镜"];
    [_randomFilterButton addTarget:self action:@selector(randomFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_randomFilterButton];
    
    self.saveToAlbumButton = [MTLivePhotoCameraButton buttonWithTitle:@"保存到相册"];
    [_saveToAlbumButton addTarget:self action:@selector(saveLivePhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_saveToAlbumButton];
    
    self.cancelPostFilterButton = [MTLivePhotoCameraButton buttonWithTitle:@"取消后期滤镜"];
    [_cancelPostFilterButton addTarget:self action:@selector(cancelPostFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelPostFilterButton];
    
    WS(ws);
    [_randomFilterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(ws.view.mas_left);
        make.right.equalTo(_saveToAlbumButton.mas_left);
        make.bottom.equalTo(ws.view.mas_bottom).with.offset(-10);
        make.height.equalTo(@40);
        make.width.equalTo(ws.view.mas_width).multipliedBy(0.5);
    }];
    [_saveToAlbumButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_randomFilterButton.mas_right);
        make.right.equalTo(ws.view.mas_right);
        make.bottom.equalTo(ws.view.mas_bottom).with.offset(-10);
        make.height.equalTo(@40);
        make.width.equalTo(ws.view.mas_width).multipliedBy(0.5);
    }];
    [_cancelPostFilterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(ws.view.mas_left).with.offset(10);
        make.top.equalTo(ws.view.mas_top).with.offset(80);
        make.size.mas_equalTo(CGSizeMake(100, 40));
    }];
    
    _randomFilterButton.hidden = YES;
    _saveToAlbumButton.hidden = YES;
    _cancelPostFilterButton.hidden = YES;

}
- (void)loadVideoWithVideoURL:(NSURL *)videoURL filter:(GPUImageOutput<GPUImageInput> *)filter
{
    self.livePhotoView.livePhoto = nil;
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    //通过AVAsset得到一副图像
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //旋转也可以获取
    generator.appliesPreferredTrackTransform = YES;
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2.f, asset.duration.timescale)]]
                                    completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                                        
                                        NSData *imageData = UIImagePNGRepresentation([filter imageByFilteringImage:[UIImage imageWithCGImage:image]]);
                                        NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory inDomains: NSUserDomainMask];
                                        NSURL *imageURL = [urls[0] URLByAppendingPathComponent:@"image.jpg"];
                                        [[NSFileManager defaultManager] removeItemAtURL:imageURL error:nil];
                                        [imageData writeToURL:imageURL atomically:YES];
                                        
                                        NSString *imagePathString = imageURL.path;
                                        NSString *movPathString = videoURL.path;
                                        
                                        NSString *assetIdentifier = [[NSUUID UUID] UUIDString];
                                        
                                        [[NSFileManager defaultManager] createDirectoryAtPath:self.cashDictionary withIntermediateDirectories:YES attributes:nil error:&error];
                                        if (!error)
                                        {
                                            [[NSFileManager defaultManager] removeItemAtPath:[self.cashDictionary stringByAppendingString:@"/image.JPG"] error:&error];
                                            [[NSFileManager defaultManager] removeItemAtPath:[self.cashDictionary stringByAppendingString:@"/image.MOV"] error:&error];
                                        }
                                        //两个assetIdentifier要相同，不然会报Invalid image/video pairing
                                        [[[MTJPEG alloc] initWithPath:imagePathString] writeToDirectory:[self.cashDictionary stringByAppendingString:@"/image.JPG"] WithAssetIdentifier:assetIdentifier];
                                        [[[MTMov alloc] initWithPath:movPathString] writeToDirectory:[self.cashDictionary stringByAppendingString:@"/image.MOV"] WithAssetIdentifier:assetIdentifier filter:filter];
                                        
                                    }];
    
}
#pragma mark 通知设置预览图
- (void)audioFinished
{
    NSArray *URLs = [NSArray arrayWithObjects:[NSURL fileURLWithPath:[self.cashDictionary stringByAppendingString:@"/image.MOV"]], [NSURL fileURLWithPath:[self.cashDictionary stringByAppendingString:@"/image.JPG"]],nil];
    
    [PHLivePhoto requestLivePhotoWithResourceFileURLs:URLs
                                     placeholderImage:nil
                                           targetSize:self.view.bounds.size
                                          contentMode:PHImageContentModeDefault
                                        resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
                                            
                                            self.livePhotoView.livePhoto = livePhoto;
                                        }];
    
}
#pragma mark 通知方法
- (void)handlerRecordFinished:(NSNotification *)sender
{
    NSString *videoPath = sender.userInfo[@"MTMovDirectory"];
    GPUImageOutput<GPUImageInput> * filter = sender.userInfo[@"MTMovFilter"];
    if ([videoPath isEqualToString:@"empty"])
    {
        return;
    }
    if (self.saveToAlbumButton.hidden || self.randomFilterButton.hidden)
    {
        self.saveToAlbumButton.hidden = NO;
        self.randomFilterButton.hidden = NO;
        self.cancelPostFilterButton.hidden = NO;
    }
    NSURL *movURL = [NSURL fileURLWithPath:videoPath];
    self.originalMovURL = movURL;
    [self loadVideoWithVideoURL:movURL filter:filter];
    
}
#pragma mark iOS10livephoto显示通知
- (void)showLivePhotoOfiOS10:(NSNotification *)sender
{
    PHAsset *livePhotoAsset = sender.userInfo[@"MTLivePhotoAsset"];
    [[PHImageManager defaultManager] requestLivePhotoForAsset:livePhotoAsset targetSize:self.view.bounds.size contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        self.livePhotoView.livePhoto = livePhoto;
    }];
    self.saveToAlbumButton.hidden = YES;
    self.randomFilterButton.hidden = YES;
    self.cancelPostFilterButton.hidden = YES;
}
//打开相机
- (IBAction)takePhoto:(UIBarButtonItem *)sender
{
    MTVideoPickerViewController *picker = [[MTVideoPickerViewController alloc] init];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark 点击事件
- (void)randomFilter:(UIButton *)button
{
    GPUImageOutput<GPUImageInput> *filter = [MTLivePhotoFilter generateRandomGPUImageFilter];
    [self loadVideoWithVideoURL:_originalMovURL filter:filter];
}
- (void)saveLivePhoto
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        
        [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:[NSURL fileURLWithPath:[self.cashDictionary stringByAppendingString:@"/image.MOV"]] options:options];
        [creationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:[NSURL fileURLWithPath:[self.cashDictionary stringByAppendingString:@"/image.JPG"]] options:options];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
    }];
}
- (void)cancelPostFilter:(UIButton *)sender
{
    //特殊滤镜
    GPUImageOutput<GPUImageInput> *filter = [[GPUImageSaturationFilter alloc] init];
    [(GPUImageSaturationFilter *)filter setSaturation:1];
    [self loadVideoWithVideoURL:_originalMovURL filter:filter];
}
@end
