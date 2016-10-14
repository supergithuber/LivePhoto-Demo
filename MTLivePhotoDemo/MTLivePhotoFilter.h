//
//  MTLivePhotoFilter.h
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/11.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage.h>

@interface MTLivePhotoFilter : NSObject

+ (GPUImageOutput<GPUImageInput> *)generateRandomGPUImageFilter;

@end
