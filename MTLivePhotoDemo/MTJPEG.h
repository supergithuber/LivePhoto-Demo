//
//  JPEG.h
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/14.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 负责读取图片，修改metadata，生成可以组成livephoto的图片
 */
@interface MTJPEG : NSObject
/**
 *  初始化函数
 *
 *  @param path 利用一个图片的路径
 *
 *  @return 返回self
 */
- (instancetype)initWithPath:(NSString *)path;
/**
 *  写入可以生成livephoto的JPEG
 *
 *  @param path            需要写入的路径
 *  @param assetIdentifier assetIdentifier,保持和mov文件的一致性
 */
- (void)writeToDirectory:(NSString *)path WithAssetIdentifier:(NSString *)assetIdentifier;
@end
