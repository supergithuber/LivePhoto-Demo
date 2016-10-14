//
//  MTVideoPickerViewController.m
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/19.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTVideoPickerViewController.h"
#import "MTCameraView.h"
@interface MTVideoPickerViewController ()<MTCameraViewDelegate>

@end

@implementation MTVideoPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = [[UIScreen mainScreen] bounds];
    MTCameraView *view = [[MTCameraView alloc] initWithFrame:frame];
    view.delegate = self;
    [self.view addSubview:view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mtCameraViewView:(MTCameraView *)cameraView didFinishRecordingWithDirectory:(NSString *)directory filter:(GPUImageOutput<GPUImageInput> *)filter
{
    if (directory == nil)
    {
        directory = @"empty";
    }

    NSDictionary *dict = @{@"MTMovDirectory" : directory, @"MTMovFilter" : filter};
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MTRecordFinished" object:self userInfo:dict];
    }];
}

@end
