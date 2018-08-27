//
//  VideoModel.h
//  DTSmallVideo
//
//  Created by quan cui on 2016/12/15.
//  Copyright © 2016年 quan cui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^combineVideoCompleteHandler) ();
@interface VideoPartModel : NSObject

@property(nonatomic, strong) NSString *partName;
@property(nonatomic, strong) NSURL *partTempFileUrl;
@property(nonatomic) CMTime partDuration;

@end



@interface DTVideoModel : NSObject
@property (nonatomic, strong) combineVideoCompleteHandler combineCompleteHandler;
@property(nonatomic, strong) NSMutableArray<VideoPartModel*> *videoParts;

@property(nonatomic, assign) CGSize videoSize;//视频大小
@property(nonatomic, strong) NSString *localFileDirectory;

@property(nonatomic, strong) NSString *videoName;
@property(nonatomic, strong) NSURL *videoTempFileUrl;
@property(nonatomic, strong) NSURL *videoExportUrl;

@property(assign) CGFloat minRecordTime;//最小的记录时间
@property(assign) CGFloat maxRecordTime;//最大的记录时间

@property(nonatomic, strong) NSURL *currentVideoPartTempFileUrl;
@property(nonatomic, strong) NSURL *currentVideoPartExportUrl;

@property(nonatomic) CMTime duration;

- (instancetype)init;

- (void)appendNewPartVideoModel;

- (void)deleteLastVideoPart;

- (void)resetVideoParts;

- (void)combineVideosToSandBoxWithCompleteHandler:(combineVideoCompleteHandler) completeHandler;
@end
