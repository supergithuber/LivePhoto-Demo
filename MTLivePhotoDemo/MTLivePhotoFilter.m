//
//  MTLivePhotoFilter.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/11.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import "MTLivePhotoFilter.h"

@implementation MTLivePhotoFilter

+ (GPUImageOutput<GPUImageInput> *)generateRandomGPUImageFilter
{
    GPUImageOutput<GPUImageInput> *filter = nil;
    NSInteger random = arc4random()%6;
    switch (random) {
        case 0:
            //素描
            filter = [[GPUImageSketchFilter alloc] init];
            break;
        case 1:
            //褐色（怀旧）
            filter = [[GPUImageSepiaFilter alloc] init];
            break;
        case 2:
            //黑色粗线描边
            filter = [[GPUImageToonFilter alloc] init];
            break;
        case 3:
            //反色
            filter = [[GPUImageColorInvertFilter alloc] init];
            break;
        case 4:
            //像素化
            filter = [[GPUImagePixellateFilter alloc] init];
            break;
        case 5:
            //浮雕
            filter = [[GPUImageEmbossFilter alloc] init];
            break;
        default:
            break;
    }
    return filter;
}

@end
