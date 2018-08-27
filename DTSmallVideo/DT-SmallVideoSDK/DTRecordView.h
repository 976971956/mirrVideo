//
//  RecordView.h
//  DTSmallVideo
//
//  Created by quan cui on 2016/12/15.
//  Copyright © 2016年 quan cui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmallVideoHeader.h"
#import "DTVideoModel.h"
#import "RecordProgressView.h"

#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSInteger, DTRecordState) {
    DTRecordStateInit,//初始化
    DTRecordStateRecording,//记录
    DTRecordStatePause,//暂停
    DTRecordStateCombining,//结合
    DTRecordStateRePlay,//重播
};

typedef NS_ENUM(NSInteger, DTTorchState) {//闪光灯状态
    DTTorchClose = 0,//关闭
    DTTorchOpen,//打开
    DTTorchAuto,//自动
};

@interface DTRecordView : UIView

@property (nonatomic) NSInteger recordState;
@property (nonatomic) NSInteger torchType;
@property (nonatomic, strong) DTVideoModel *videoModel;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)startRecord;
- (void)pauseRecord;
- (void)finishVideoRecord;

- (void)selectLastDeletePart;
- (void)didDeleteLastPart;
- (void)resetRecord;

- (void)switchTorch;
- (void)switchCamera;

@end
