//
//  MTLivePhotoVideoTool.h
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/25.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define MTLivePhotoMergeVideoPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/mergeVideo.mov"]

@interface MTLivePhotoVideoTool : NSObject
/**
 *  合并这两段视频
 *
 *  @param firstAssetPath  第一段视频路径
 *  @param secondAssetPath 第二段视频路径
 *  @param complete    回调返回exportor
 */
+ (void)mergeAsset:(NSString *)firstAssetPath
         withAsset:(NSString *)secondAssetPath
        completion:(void(^)(AVAssetExportSession *exportor))complete;
/**
 *  合并多段视频
 *
 *  @param fileURLs   文件路径
 *  @param completion 结束回调
 */
+ (void)mergeVideoFiles:(NSMutableArray *)fileURLs
             completion:(void(^)(AVAssetExportSession * exportor))completion;
/**
 *  返回用于合成livephoto的文件
 *
 *  @param assetPath 一段视频路径
 *  @param clickTime livephoto中点击时间距离视频起始点的时间
 *  @param path      导出的路径
 *  @param complete  结束回调
 */
+ (void)exportAsset:(NSString *)assetPath
      withMediaTime:(CGFloat)clickTime
             toPath:(NSString *)path
         completion:(void(^)(AVAssetExportSession *exportor))complete;
/**
 *  返回多媒体文件时长
 *
 *  @param mediaUrlStr 媒体文件路径
 *
 *  @return 时长
 */
+ (CGFloat)getMediaDurationWithMediaUrl:(NSString *)mediaUrlStr;
@end
