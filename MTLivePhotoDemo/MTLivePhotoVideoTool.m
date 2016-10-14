//
//  MTLivePhotoVideoTool.m
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/25.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTLivePhotoVideoTool.h"

@implementation MTLivePhotoVideoTool

+ (void)mergeAsset:(NSString *)firstAssetPath
         withAsset:(NSString *)secondAssetPath
        completion:(void(^)(AVAssetExportSession *exportor))complete
{
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstAssetPath] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondAssetPath] options:optDict];
    // 1 - AVMutableComposition 对象
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // 2 - 视频和音频轨
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *firstVideoTrack = [firstAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrack *firstAudioTrack = [firstAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    CMTime firstVideoDuration = firstVideoTrack.timeRange.duration;
    CMTime firstAudioDuration = firstAudioTrack.timeRange.duration;
    
    AVAssetTrack *secondVideoTrack = [secondAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrack *secondAudioTrack = [secondAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    CMTime secondVideoDuration = secondVideoTrack.timeRange.duration;
    CMTime secondAudioDuration = secondAudioTrack.timeRange.duration;
    
    if (firstVideoTrack)
    {
        //第一段
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoDuration)
                            ofTrack:firstVideoTrack atTime:kCMTimeZero error:nil];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAudioDuration)
                            ofTrack:firstAudioTrack atTime:kCMTimeZero error:nil];
        //第二段
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoDuration)
                            ofTrack:secondVideoTrack atTime:firstVideoDuration error:nil];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAudioDuration)
                            ofTrack:secondAudioTrack atTime:firstAudioDuration error:nil];
    }
    else
    {
        //一开始就录制，导致失去第一段视频
        //第二段
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoDuration)
                            ofTrack:secondVideoTrack atTime:kCMTimeZero error:nil];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAudioDuration)
                            ofTrack:secondAudioTrack atTime:kCMTimeZero error:nil];
    }
 
    // 4 - 路径
    unlink([MTLivePhotoMergeVideoPath UTF8String]);
    NSURL *url = [NSURL fileURLWithPath:MTLivePhotoMergeVideoPath];
    // 5 - 导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (complete) {
            complete(exporter);
        }
    }];
    
}

+ (void)mergeVideoFiles:(NSMutableArray *)fileURLs
             completion:(void(^)(AVAssetExportSession * exportor))completion {
    //起始没有第一段视频
    AVAsset *firstAsset = [AVURLAsset assetWithURL:(NSURL *)fileURLs.firstObject];
    if (![firstAsset tracksWithMediaType:AVMediaTypeVideo].firstObject)
    {
        [fileURLs removeObjectAtIndex:0];
    }
//    NSLog(@"%lu",(unsigned long)fileURLs.count);
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    NSMutableArray *instructions = [NSMutableArray new];
    
    __block CMTime currentTime = kCMTimeZero;
    __block CGSize size = CGSizeZero;
    __block int32_t highestFrameRate = 0;
    
    [fileURLs enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
#pragma unused(idx)
        
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:fileURL options:options];
        AVAssetTrack *videoAsset = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioAsset = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (CGSizeEqualToSize(size, CGSizeZero)) { size = videoAsset.naturalSize; }
        
        int32_t currentFrameRate = (int)roundf(videoAsset.nominalFrameRate);
        highestFrameRate = (currentFrameRate > highestFrameRate) ? currentFrameRate : highestFrameRate;
        
//        NSLog(@"* %@ (%dfps)", [fileURL lastPathComponent], currentFrameRate);
        CMTime trimmingTime = CMTimeMake(lround(videoAsset.naturalTimeScale / videoAsset.nominalFrameRate), videoAsset.naturalTimeScale);
        CMTimeRange timeRange = CMTimeRangeMake(trimmingTime, CMTimeSubtract(videoAsset.timeRange.duration, trimmingTime));
        
        NSError *videoError;
        [videoTrack insertTimeRange:timeRange ofTrack:videoAsset atTime:currentTime error:&videoError];
        
        NSError *audioError;
        [audioTrack insertTimeRange:timeRange ofTrack:audioAsset atTime:currentTime error:&audioError];
        
            AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            videoCompositionInstruction.timeRange = CMTimeRangeMake(currentTime, timeRange.duration);
            videoCompositionInstruction.layerInstructions = @[[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack]];
            [instructions addObject:videoCompositionInstruction];
            
            currentTime = CMTimeAdd(currentTime, timeRange.duration);
        
    }];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    unlink([MTLivePhotoMergeVideoPath UTF8String]);
    exportSession.outputURL = [NSURL fileURLWithPath:MTLivePhotoMergeVideoPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = instructions;
    mutableVideoComposition.frameDuration = CMTimeMake(1, highestFrameRate);
    mutableVideoComposition.renderSize = size;
    exportSession.videoComposition = mutableVideoComposition;
    
//    NSLog(@"Composition Duration: %ld seconds", lround(CMTimeGetSeconds(composition.duration)));
//    NSLog(@"Composition Framerate: %d fps", highestFrameRate);
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(exportSession);
            }
        });
        
    }];

}

+ (void)exportAsset:(NSString *)assetPath
      withMediaTime:(CGFloat)clickTime
             toPath:(NSString *)path
         completion:(void (^)(AVAssetExportSession *))complete
{
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:assetPath] options:optDict];
    AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrack *assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    CGFloat startTime = (clickTime - 1.5f < 0)? 0 : clickTime - 1.5f;
    CGFloat continuedTime = (CMTimeGetSeconds(asset.duration) < 3.0f)? CMTimeGetSeconds(asset.duration) : 3.0f;
//    NSLog(@"拼接视频总时长%f",CMTimeGetSeconds(asset.duration));
//    NSLog(@"点击时间%f",clickTime);
    //视频
    AVMutableCompositionTrack * videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, asset.duration.timescale), CMTimeMakeWithSeconds(continuedTime, asset.duration.timescale)) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
    //声音
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, asset.duration.timescale), CMTimeMakeWithSeconds(continuedTime, asset.duration.timescale)) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
    
    unlink([path UTF8String]);
    NSURL *url = [NSURL fileURLWithPath:path];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (complete)
        {
            complete(exporter);
        }
    }];
}
+ (CGFloat)getMediaDurationWithMediaUrl:(NSString *)mediaUrlStr {
    
    NSURL *mediaUrl = [NSURL fileURLWithPath:mediaUrlStr];
    AVURLAsset *mediaAsset = [[AVURLAsset alloc] initWithURL:mediaUrl options:nil];
    
    return CMTimeGetSeconds(mediaAsset.duration);
}
@end
