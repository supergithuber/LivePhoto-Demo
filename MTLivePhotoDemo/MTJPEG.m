//
//  JPEG.m
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/14.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import "MTJPEG.h"

NSString *const kFigAppleMakerNote_AssetIdentifier = @"17";

@interface MTJPEG ()

@property (nonatomic, retain)NSString *path;

@end
@implementation MTJPEG

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init])
    {
        self.path = path;
    }
    return self;
}
- (void)writeToDirectory:(NSString *)path WithAssetIdentifier:(NSString *)assetIdentifier
{
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], kUTTypeJPEG, 1, nil);
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)[NSData dataWithContentsOfFile:self.path], nil);
    NSMutableDictionary *metaData = [(__bridge_transfer  NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) mutableCopy];
    
    NSMutableDictionary *makerNote = [NSMutableDictionary dictionary];
    [makerNote setValue:assetIdentifier forKey:kFigAppleMakerNote_AssetIdentifier];
    [metaData setValue:makerNote forKey:(__bridge_transfer  NSString*)kCGImagePropertyMakerAppleDictionary];
    CGImageDestinationAddImageFromSource(dest, imageSourceRef, 0, (CFDictionaryRef)metaData);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    
}
@end
