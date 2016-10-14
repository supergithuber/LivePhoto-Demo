//
//  MTLivePhotoCaptureViewController.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/8.
//  Copyright © 2016年 wuxi. All rights reserved.
//
#import <Photos/Photos.h>
#import "MTLivePhotoCaptureViewController.h"
#import "MTLivePhotoPreview.h"
#import "MTLivePhotoCaptureSessionManager.h"
#import "UIViewController+MTAlert.h"

@interface MTLivePhotoCaptureViewController ()
{
    NSInteger _sessionRunningObserveContext;
}
@property (weak, nonatomic) IBOutlet MTLivePhotoPreview *previewView;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UILabel *capturingLivePhotoLabel;

@end

@implementation MTLivePhotoCaptureViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MTSuccessSaveLivePhoto" object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNotification];
    _sessionRunningObserveContext = 0;
    MTLivePhotoCaptureSessionManager *manager = [MTLivePhotoCaptureSessionManager sharedManager];
    self.previewView.session = manager.session;
    [manager authorize];
    [manager configureSession];
    
}
- (void)initNotification;
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successSaveLivePhoto:) name:@"MTSuccessSaveLivePhoto" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MTLivePhotoCaptureSessionManager sharedManager] startSession:^(BOOL result) {
        if (result)
        {
            [self addObservers];
        }else
        {
            switch ([MTLivePhotoCaptureSessionManager sharedManager].result) {
                case sessionSuccess:
                    break;
                case sessionNotAuthorized:
                    [self mt_showAlertWithTitle:@"未授权" Message:@"未授权打开相机，请更改隐私设置"];
                    break;
                case sessionNotSupported:
                    [self mt_showAlertWithTitle:@"不支持" Message:@"对不起，您的设备不支持拍摄livephoto"];
                    break;
                case sessionConfigurationFailed:
                    [self mt_showAlertWithTitle:@"配置失败" Message:@"配置会话失败"];
                    break;
                default:
                    break;
            }
        }
    }];
}
- (void)viewWillDisappear:(BOOL)animated
{
    if ([MTLivePhotoCaptureSessionManager sharedManager].isSessionRunning)
    {
        [[MTLivePhotoCaptureSessionManager sharedManager] stopSession];
        [self removeObservers];
    }
    [super viewWillDisappear:animated];
}
- (void)addObservers
{
    [[MTLivePhotoCaptureSessionManager sharedManager].session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:&_sessionRunningObserveContext];
}
- (void)removeObservers
{
    [[MTLivePhotoCaptureSessionManager sharedManager].session removeObserver:self forKeyPath:@"running" context:&_sessionRunningObserveContext];
}
#pragma mark KVC
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == &_sessionRunningObserveContext)
    {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        if (isSessionRunning)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _photoButton.enabled = isSessionRunning;
            });
        }else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)capturePhoto:(UIButton *)sender {
    AVCaptureVideoOrientation videoPreviewLayerOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
    [[MTLivePhotoCaptureSessionManager sharedManager] captureWithVideoOrientation:videoPreviewLayerOrientation completion:^(NSInteger count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (count > 0)
            {
                _capturingLivePhotoLabel.hidden = NO;
            }else if (count == 0)
            {
                _capturingLivePhotoLabel.hidden = YES;
            }else
            {
                NSLog(@"less than 0");
            }
            
        });
    }];
}
//切换前后置
- (IBAction)swapCamera:(UIButton *)sender {
    [[MTLivePhotoCaptureSessionManager sharedManager] swapBackAndFrontCamera];
}

#pragma mark 通知方法
- (void)successSaveLivePhoto:(NSNotification *)notification
{
    //在notification的userinfo中的MTLivePhotoAsset可以拿到最新拍摄的livephoto的PHAsset
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MTConvertiOS10LivePhoto" object:self userInfo:notification.userInfo];
    }];
}

@end
