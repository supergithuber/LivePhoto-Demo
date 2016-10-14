//
//  MTCameraView.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/9/19.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTCameraView.h"
#import "Masonry.h"
#import "MTLivePhotoCameraButton.h"
#import "MTLivePhotoVideoTool.h"
#import "MTLivePhotoFilter.h"

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define MTLivePhotoFirstMoviePath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/firstMovie.MOV"];
#define MTLivePhotoSecondMoviePath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/secondMovie.MOV"];
#define MTLivePhotoFinalMoviePath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.MOV"];

//循环拍摄时间
static const CGFloat kCaptureCirculateTime = 2.0f;
//点击按钮后延迟拍摄时间
static const CGFloat kCaptureTimeAfterClick = 1.7f;

@interface MTCameraView () <CAAnimationDelegate>

@property (nonatomic, retain)GPUImageVideoCamera *videoCamera;
@property (nonatomic, retain)GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, copy)NSString *pathToMovie;
@property (nonatomic, retain)GPUImageView *filteredVideoView;
@property (nonatomic, retain)CALayer *focusLayer;
//GCD定时器
@property (nonatomic, strong)dispatch_source_t circulateTimer;
@property (nonatomic, strong)dispatch_queue_t myQueue;

@property (nonatomic, retain)NSDate *fromDate;
@property (nonatomic, assign)NSTimeInterval fromClickToBegin;
@property (nonatomic, assign)CGRect mainScreenFrame;
@property (nonatomic, retain)UISlider *filterSettingsSlider;

//提前写，用于采集livephoto拍摄前的视频
@property (nonatomic, retain)GPUImageMovieWriter *firstMovieWriter;
@property (nonatomic, copy)NSString *firstMoviePath;

@property (nonatomic, retain)NSURL *firstMovieURL;
@property (nonatomic, retain)GPUImageMovieWriter *secondMovieWriter;
@property (nonatomic, copy)NSString *secondMoviePath;
@property (nonatomic, retain)NSURL *secondMovieURL;

//GCD无法终止queue,通过逻辑控制
@property (nonatomic, assign)BOOL shouldNotExchange;

@end
@implementation MTCameraView
- (instancetype) initWithFrame:(CGRect)frame{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    _mainScreenFrame = frame;
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera addAudioInputsAndOutputs];
    _filter = [[GPUImageSaturationFilter alloc] init];
    _filteredVideoView = [[GPUImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [_videoCamera addTarget:_filter];
    
    [_filter addTarget:_filteredVideoView];
    [_videoCamera startCameraCapture];
    [self addSomeView];
    [self startLivePhotoCapture];
    [self addSubview:_filteredVideoView];
    //手势聚焦
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
        singleFingerOne.numberOfTouchesRequired = 1; //手指数
        singleFingerOne.numberOfTapsRequired = 1; //tap次数
        [_filteredVideoView addGestureRecognizer:singleFingerOne];
    });
    
    return self;
    
}

- (void)addSomeView{
    self.filterSettingsSlider = [[UISlider alloc] init];
    [_filterSettingsSlider addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
    _filterSettingsSlider.minimumValue = 0.0;
    _filterSettingsSlider.maximumValue = 2.0;
    _filterSettingsSlider.value = 1.0;
    _filterSettingsSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.filteredVideoView addSubview:_filterSettingsSlider];
    
    MTLivePhotoCameraButton *photoCaptureButton = [MTLivePhotoCameraButton buttonWithTitle:@"开始录制"];
    [photoCaptureButton addTarget:self action:@selector(startRecording:) forControlEvents:UIControlEventTouchUpInside];
    [_filteredVideoView addSubview:photoCaptureButton];
    
    MTLivePhotoCameraButton *randomFilterButton = [MTLivePhotoCameraButton buttonWithTitle:@"随机实时滤镜"];
    [randomFilterButton addTarget:self action:@selector(randomRealTimeFilter:) forControlEvents:UIControlEventTouchUpInside];
    [_filteredVideoView addSubview:randomFilterButton];
    
    MTLivePhotoCameraButton *cancelFilterButton = [MTLivePhotoCameraButton buttonWithTitle:@"取消滤镜"];
    [cancelFilterButton addTarget:self action:@selector(cancenlFilter:) forControlEvents:UIControlEventTouchUpInside];
    [_filteredVideoView addSubview:cancelFilterButton];
    
    MTLivePhotoCameraButton *rotateCameraButton = [MTLivePhotoCameraButton buttonWithTitle:@"切换摄像头"];
    [rotateCameraButton addTarget:self action:@selector(rotateCamera:) forControlEvents:UIControlEventTouchUpInside];
    [_filteredVideoView addSubview:rotateCameraButton];
    
    [_filterSettingsSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_filteredVideoView).with.offset(30);
        make.left.equalTo(_filteredVideoView).with.offset(10);
        make.right.equalTo(_filteredVideoView).with.offset(-10);
        make.height.equalTo(@40);
    }];
    [photoCaptureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_filteredVideoView.mas_left).with.offset(10);
        make.right.equalTo(randomFilterButton.mas_left).with.offset(-10);
        make.bottom.equalTo(_filteredVideoView.mas_bottom).with.offset(-10);
        make.height.equalTo(@40);
        make.width.equalTo(randomFilterButton);
    }];
    [randomFilterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(photoCaptureButton.mas_right).with.offset(10);
        make.right.equalTo(_filteredVideoView.mas_right).with.offset(-10);
        make.bottom.equalTo(_filteredVideoView.mas_bottom).with.offset(-10);
        make.height.equalTo(@40);
        make.width.equalTo(randomFilterButton);
    }];
    [cancelFilterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_filterSettingsSlider.mas_bottom).with.offset(10);
        make.left.equalTo(_filteredVideoView.mas_left).with.offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    [rotateCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_filterSettingsSlider.mas_bottom).with.offset(10);
        make.right.equalTo(_filteredVideoView.mas_right).with.offset(-10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
}

- (void)startLivePhotoCapture
{
    //初始化第一个写入者
    _firstMoviePath = MTLivePhotoFirstMoviePath;
    unlink([_firstMoviePath UTF8String]);
    _firstMovieURL = [NSURL fileURLWithPath:_firstMoviePath];
    _firstMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_firstMovieURL size:CGSizeMake(360.0, 640.0)];
    _firstMovieWriter.encodingLiveVideo = YES;
    _firstMovieWriter.shouldPassthroughAudio = YES;
    //第二个写入者
    _secondMoviePath = MTLivePhotoSecondMoviePath;
    unlink([_secondMoviePath UTF8String]);
    _secondMovieURL = [NSURL fileURLWithPath:_secondMoviePath];
//    _secondMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_secondMovieURL size:CGSizeMake(360.0, 640.0)];
//    _secondMovieWriter.encodingLiveVideo = YES;
//    _secondMovieWriter.shouldPassthroughAudio = YES;
    //让第一个开始录制
    [_videoCamera addTarget:_firstMovieWriter];
    _videoCamera.audioEncodingTarget = _firstMovieWriter;
    [_firstMovieWriter startRecording];
    //GCD循环执行切换writer,间隔kCaptureCirculateTime秒
    self.myQueue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    self.circulateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.myQueue);
    dispatch_source_set_timer(self.circulateTimer, DISPATCH_TIME_NOW, kCaptureCirculateTime*NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(self.circulateTimer, ^{
        if (!self.shouldNotExchange)
        {
            [self startExchangeWriter];
        }
    });
    dispatch_resume(self.circulateTimer);
}
- (void)startExchangeWriter
{
    if (_videoCamera.audioEncodingTarget == _firstMovieWriter)
    {
        //结束第一个的录制
        _videoCamera.audioEncodingTarget = nil;
        [_firstMovieWriter finishRecording];
        [_videoCamera removeTarget:_firstMovieWriter];
        //开启第二个的录制
        unlink([_secondMoviePath UTF8String]);
        _secondMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_secondMovieURL size:CGSizeMake(360.0, 640.0)];
        _secondMovieWriter.encodingLiveVideo = YES;
        _secondMovieWriter.shouldPassthroughAudio = YES;
        [_videoCamera addTarget:_secondMovieWriter];
        _videoCamera.audioEncodingTarget = _secondMovieWriter;
        [_secondMovieWriter startRecording];
        _fromDate = [NSDate date];
//        NSLog(@"第二个开始录像");
    }else
    {
        //结束第二个的录制
        _videoCamera.audioEncodingTarget = nil;
        [_secondMovieWriter finishRecording];
        [_videoCamera removeTarget:_secondMovieWriter];
        //开启第一个的录制,重新创建,不然会报[AVAssetWriter startWriting] Cannot call method when status is 3
        unlink([_firstMoviePath UTF8String]);
        _firstMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_firstMovieURL size:CGSizeMake(360.0, 640.0)];
        _firstMovieWriter.encodingLiveVideo = YES;
        _firstMovieWriter.shouldPassthroughAudio = YES;
        [_videoCamera addTarget:_firstMovieWriter];
        _videoCamera.audioEncodingTarget = _firstMovieWriter;
        [_firstMovieWriter startRecording];
        _fromDate = [NSDate date];
//        NSLog(@"第一个开始录像");
    }
}
#pragma mark 点击事件
- (void)randomRealTimeFilter:(id)sender
{
    if (!self.filterSettingsSlider.hidden)
    {
        self.filterSettingsSlider.hidden = YES;
    }
    [self.videoCamera removeAllTargets];
    [self.filter removeAllTargets];
    self.filter = [MTLivePhotoFilter generateRandomGPUImageFilter];
    [self.videoCamera addTarget:_filter];
    [_filter addTarget:self.filteredVideoView];
}
- (void)cancenlFilter:(UIButton *)sender
{
    if (!self.filterSettingsSlider.hidden)
    {
        self.filterSettingsSlider.hidden = YES;
    }
    [self.videoCamera removeAllTargets];
    [self.filter removeAllTargets];
    //由于字典value不能为nil，这里用一种特殊滤镜替代没有滤镜的情况，后面逻辑中再判断不加滤镜
    self.filter = [[GPUImageSaturationFilter alloc] init];
    [(GPUImageSaturationFilter *)_filter setSaturation:1];
    
    [self.videoCamera addTarget:_filter];
    [_filter addTarget:self.filteredVideoView];
}
- (void)rotateCamera:(UIButton *)sender
{
    [_videoCamera rotateCamera];
}
- (void)updateSliderValue:(id)sender
{
    [(GPUImageSaturationFilter *)_filter setSaturation:[(UISlider *)sender value]];
}

- (void)startRecording:(id)sender {
    _pathToMovie = MTLivePhotoFinalMoviePath;
    unlink([_pathToMovie UTF8String]); // 移除文件
    //记录点击拍摄的时间
    _fromClickToBegin = [[NSDate date] timeIntervalSinceDate:_fromDate];
    self.shouldNotExchange = YES;
    //延迟kCaptureTimeAfterClick秒，防止第二段起始录制太短
    WS(ws);
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCaptureTimeAfterClick * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [ws stopRecording:nil];
    });
    
}

- (void)stopRecording:(id)sender {
    if (_videoCamera.audioEncodingTarget == _firstMovieWriter)
    {
        _videoCamera.audioEncodingTarget = nil;
        [_firstMovieWriter finishRecording];
        [_videoCamera removeTarget:_firstMovieWriter];
        //关闭计时器
        dispatch_source_cancel(self.circulateTimer);
        
        NSMutableArray *URLArrays = [NSMutableArray arrayWithObjects:self.secondMovieURL, self.firstMovieURL,nil];
        [MTLivePhotoVideoTool mergeVideoFiles:URLArrays completion:^(AVAssetExportSession *exportor) {
//            NSLog(@"从第一个终止完成合并");
            //需要加上前一段视频的时间
            _fromClickToBegin += [MTLivePhotoVideoTool getMediaDurationWithMediaUrl:self.secondMoviePath];
            [MTLivePhotoVideoTool exportAsset:MTLivePhotoMergeVideoPath withMediaTime:self.fromClickToBegin toPath:self.pathToMovie completion:^(AVAssetExportSession *exportor) {
//                NSLog(@"从第一个提取完成");
                if ([_delegate respondsToSelector:@selector(mtCameraViewView:didFinishRecordingWithDirectory:filter:)])
                {
                    [self.delegate mtCameraViewView:self didFinishRecordingWithDirectory:self.pathToMovie filter:self.filter];
                }
            }];
        }];
    }
    else
    {
        _videoCamera.audioEncodingTarget = nil;
        [_secondMovieWriter finishRecording];
        //移除
        [_videoCamera removeTarget:_secondMovieWriter];
        
        dispatch_source_cancel(self.circulateTimer);
        NSMutableArray *URLArrays = [NSMutableArray arrayWithObjects:self.firstMovieURL, self.secondMovieURL,nil];
        [MTLivePhotoVideoTool mergeVideoFiles:URLArrays completion:^(AVAssetExportSession *exportor) {
//            NSLog(@"从第二个终止完成合并");
            _fromClickToBegin += [MTLivePhotoVideoTool getMediaDurationWithMediaUrl:self.firstMoviePath];
            [MTLivePhotoVideoTool exportAsset:MTLivePhotoMergeVideoPath withMediaTime:self.fromClickToBegin toPath:self.pathToMovie completion:^(AVAssetExportSession *exportor) {
//                NSLog(@"从第二个提取完成");
                if ([_delegate respondsToSelector:@selector(mtCameraViewView:didFinishRecordingWithDirectory:filter:)])
                {
                    [self.delegate mtCameraViewView:self didFinishRecordingWithDirectory:self.pathToMovie filter:self.filter];
                }
            }];
        }];
    }
    
}


- (void)setfocusImage{
    UIImage *focusImage = [UIImage imageNamed:@"focus"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, focusImage.size.width, focusImage.size.height)];
    imageView.image = focusImage;
    CALayer *layer = imageView.layer;
    layer.hidden = YES;
    [_filteredVideoView.layer addSublayer:layer];
    _focusLayer = layer;
}


- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.delegate = self;
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
        // 0.5秒钟延时
        [self performSelector:@selector(focusLayerNormal) withObject:self afterDelay:0.5f];
    }
}


- (void)focusLayerNormal {
    
    _filteredVideoView.userInteractionEnabled = YES;
    
    _focusLayer.hidden = YES;
    
}

#pragma mark 手势识别
-(void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized && (_focusLayer == NO || _focusLayer.hidden)) {
        CGPoint location = [tgr locationInView:_filteredVideoView];
        [self setfocusImage];
        [self layerAnimationWithPoint:location];
        AVCaptureDevice *device = self.videoCamera.inputCamera;
//        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [self.filteredVideoView frame].size;
        if ([_videoCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
            
        }
        CGPoint pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                    
                {
                    
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                    
                }
                [device unlockForConfiguration];
//                NSLog(@"FOCUS OK");
            } else {
                
                NSLog(@"ERROR = %@", error);  
            }  
        }  
    }  
}
@end
