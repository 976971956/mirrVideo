//
//  RecordView.m
//  DTSmallVideo
//
//  Created by quan cui on 2016/12/15.
//  Copyright © 2016年 quan cui. All rights reserved.
//

#import "DTRecordView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DTRecordView()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) MPMoviePlayerController *videoPlayer;

@end
@implementation DTRecordView{
    //captureInput
    AVCaptureSession *_cameraSession;//管理捕获活动并协调从输入设备到捕获输出的数据流的对象。
    AVCaptureVideoPreviewLayer *_videoPreViewLayer;//核心动画层，可以在捕获视频时显示视频。
    AVCaptureDevice *_cameraDevice;//一种为捕获会话提供输入（如音频或视频）并为特定于硬件的捕获功能提供控制的设备。
    AVCaptureVideoDataOutput *_videoDataOutPut;//捕获输出，用于记录视频并提供对视频帧的访问以进行处理。
    AVCaptureAudioDataOutput *_audioDataOutPut;//捕获输出，记录音频并在记录时提供对音频采样缓冲区的访问。
    //writerOutPut
    AVAssetWriter *_assetWriter;//用于将媒体数据写入指定视听容器类型的新文件的对象。
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterPixelBufferInput;//用于将打包为像素缓冲区的视频样本附加到单个资产编写器输入的缓冲区。
    AVAssetWriterInput *_assetWriterVideoInput;//用于将媒体示例附加到AVAssetWriter对象的输出文件的单个轨道的编写器。
    AVAssetWriterInput *_assetWriterAudioInput;//用于将媒体示例附加到AVAssetWriter对象的输出文件的单个轨道的编写器。
    
    CMTime _currentSampleTime;//表示时间值的结构，例如时间戳或持续时间。
    CMTime _startRecordTime;
    CMTime _previousFrameTime;
    
    dispatch_queue_t _videoRecordQueue;
    BOOL _isRecording;
    NSError *_assetWriterError;
    RecordProgressView *_progressView;
    
    NSArray *_devicesVideo;
    AVCaptureDeviceInput *_videoInput;//捕获输入，用于将捕获设备中的媒体提供给捕获会话。
}
- (instancetype)initWithFrame:(CGRect)frame{
    if(self  == [super initWithFrame:frame]){
        //setUp Video Configuration
        _videoModel = [[DTVideoModel alloc]init];
        CGFloat ratio = self.frame.size.width/self.frame.size.height;
        _videoModel.videoSize = CGSizeMake(640, 640/ratio);
        _videoModel.minRecordTime = 2;
        _videoModel.maxRecordTime = 10;
        
        _torchType = DTTorchClose;//闪光灯关闭状态
        [self setupCameraSession];//设置会话
        [self setUpProgressView];//设置进度条
        self.recordState = DTRecordStateInit;
    }
    return self;
}
- (void)setupCameraSession{
    NSString *unUseInfo = nil;
    if (TARGET_IPHONE_SIMULATOR) {
        unUseInfo = @"simulator prehibited";
    }
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//获取设备权限信息。提供有关使用媒体捕获设备的许可的信息的常量。
    if(videoAuthStatus == ALAuthorizationStatusRestricted || videoAuthStatus == ALAuthorizationStatusDenied){
        unUseInfo = @"没有打开相机权限";
        NSLog(@"%@",unUseInfo);

    }
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(audioAuthStatus == ALAuthorizationStatusRestricted || audioAuthStatus == ALAuthorizationStatusDenied){
        unUseInfo = @"没有打开语音权限";
        NSLog(@"%@",unUseInfo);

    }
    //创建串行队列
    _videoRecordQueue = dispatch_queue_create("com.DreamTreeTech", DISPATCH_QUEUE_SERIAL);
    
    _devicesVideo = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];//返回能够捕获视频类型数据的设备数组。
    NSArray *devicesAudio = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];//返回能够捕获音频类型数据的设备数组。
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_devicesVideo[0] error:nil];//第一个视频设备输入对象
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:devicesAudio[0] error:nil];
    
    _cameraDevice = _devicesVideo[0];//视频设备
    
    _videoDataOutPut = [[AVCaptureVideoDataOutput alloc] init];//视频输出对象
    _videoDataOutPut.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};//设置视频输出显示模式
    _videoDataOutPut.alwaysDiscardsLateVideoFrames = YES;//指示视频帧是否在迟到时被丢弃。
    [_videoDataOutPut setSampleBufferDelegate:self queue:_videoRecordQueue];//设置将接受捕获的缓冲区和将调用委托的调度队列的委托。
    
    _audioDataOutPut = [[AVCaptureAudioDataOutput alloc] init];//音频输出对象
    [_audioDataOutPut setSampleBufferDelegate:self queue:_videoRecordQueue];
    
    _cameraSession = [[AVCaptureSession alloc] init];
    if ([_cameraSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        _cameraSession.sessionPreset = AVCaptureSessionPreset640x480;//设定视频尺寸
    }
    if ([_cameraSession canAddInput:_videoInput]) {
        [_cameraSession addInput:_videoInput];//添加视频输入
    }
    if ([_cameraSession canAddInput:audioInput]) {
        [_cameraSession addInput:audioInput];//添加音频输入
    }
    if ([_cameraSession canAddOutput:_videoDataOutPut]) {
        [_cameraSession addOutput:_videoDataOutPut];//添加视频输出
    }
    if ([_cameraSession canAddOutput:_audioDataOutPut]) {
        [_cameraSession addOutput:_audioDataOutPut];//添加音频输出
    }
    _videoPreViewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_cameraSession];//核心动画层
    _videoPreViewLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height-1);
    _videoPreViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//一个值，用于定义视频在图层边界矩形内的显示方式。
    [self.layer addSublayer:_videoPreViewLayer];
    [_cameraSession startRunning];
}
- (void)setUpProgressView{
    //设置进度条
    _progressView = [[RecordProgressView alloc]initWithFrame:CGRectMake(0, kScreenWidth-1, kScreenWidth, 1) minTime:_videoModel.minRecordTime maxTime:_videoModel.maxRecordTime];
    [self addSubview:_progressView];
}
#pragma mark - 开关灯
- (void)switchTorch{

    if(_torchType == DTTorchClose){//开灯
        if ([_cameraDevice hasTorch]) {
            [_cameraDevice lockForConfiguration:nil];
            [_cameraDevice setTorchMode:AVCaptureTorchModeOn];  // use AVCaptureTorchModeOff to turn off
            [_cameraDevice unlockForConfiguration];
            _torchType = DTTorchOpen;
        }
    }else if(_torchType == DTTorchOpen){//关灯
        if ([_cameraDevice hasTorch]) {
            [_cameraDevice lockForConfiguration:nil];
            [_cameraDevice setTorchMode:AVCaptureTorchModeOff];  // use AVCaptureTorchModeOff to turn off
            [_cameraDevice unlockForConfiguration];
            _torchType = DTTorchClose;
        }
    };
}
#pragma mark - 切换摄像头
- (void)switchCamera{
    
    [_cameraSession stopRunning];//告诉接收器停止运行。
    if(_cameraDevice.position == AVCaptureDevicePositionBack){
        AVCaptureConnection *connection =  [_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        NSLog(@"%@镜像",connection.supportsVideoMirroring?@"支持":@"不支持");
        [_cameraSession removeInput:_videoInput];
        _cameraDevice = _devicesVideo[1];
        _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_cameraDevice error:nil];
        [_cameraSession addInput:_videoInput];


    }else if(_cameraDevice.position == AVCaptureDevicePositionFront||_cameraDevice.position == AVCaptureDevicePositionUnspecified){
        AVCaptureConnection *connection = [_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        connection.automaticallyAdjustsVideoMirroring = YES;
        NSLog(@"%@镜像",connection.supportsVideoMirroring?@"支持":@"不支持");
        [_cameraSession removeInput:_videoInput];
        _cameraDevice = _devicesVideo[0];
        _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_cameraDevice error:nil];
        [_cameraSession addInput:_videoInput];
    }
    [_cameraSession startRunning];//告诉接收器开始运行。
    
}

- (void)startRecord{//开始记录
    self.recordState = DTRecordStateRecording;
    if(!_assetWriter){
        [_progressView resetProgress];
    }else{
        [_videoModel appendNewPartVideoModel];
    }
    [self setUpAssetWriter];
    _isRecording = YES;
}

- (void)pauseRecord{//暂停记录
    _isRecording = NO;
    self.recordState = DTRecordStatePause;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(_videoRecordQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^{
                CGFloat newSecs = CMTimeGetSeconds(CMTimeSubtract(_currentSampleTime, _startRecordTime));
                
                CMTime newDuration = CMTimeMakeWithSeconds(newSecs, _currentSampleTime.timescale);
    
                [_videoModel.videoParts lastObject].partDuration = newDuration;
            }];
        });
    }
}

- (void)resetRecord{//删除、重置
    self.recordState = DTRecordStateInit;
    if(self.videoPlayer){
        [self.videoPlayer stop];
        [self.videoPlayer.view removeFromSuperview];
    }
    [_videoModel resetVideoParts];
    [_progressView deleteAllProgressViews];
    [_cameraSession startRunning];
}

#pragma mark -- 完成录制
- (void)finishVideoRecord{
    _isRecording = NO;
    self.recordState = DTRecordStateCombining;
    [_cameraSession stopRunning];//暂停会话

    [_videoModel combineVideosToSandBoxWithCompleteHandler:^{
        [_cameraSession stopRunning];
        [_progressView deleteAllProgressViews];
        [self replayVideo];
    }];
}
//最大录制时间结束
- (void)finishVideoWithTimeOut{
    _isRecording = NO;
    self.recordState = DTRecordStateCombining;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(_videoRecordQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^{
                [_videoModel combineVideosToSandBoxWithCompleteHandler:^{
                    [_cameraSession stopRunning];
                    [_progressView deleteAllProgressViews];
                    [self replayVideo];
                }];
            }];
        });
    }
}

//重播视频
- (void)replayVideo{
    //replay VIdeo
    self.recordState = DTRecordStateRePlay;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.videoModel.videoExportUrl];
        [self.videoPlayer.view setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:self.videoPlayer.view];
        [self bringSubviewToFront:self.videoPlayer.view];
        [self.videoPlayer prepareToPlay];
        self.videoPlayer.controlStyle = MPMovieControlStyleNone;
        self.videoPlayer.shouldAutoplay = YES;
        self.videoPlayer.repeatMode = MPMovieRepeatModeOne;
        [self.videoPlayer play];
    });
}

- (void)selectLastDeletePart{
    [_progressView willDeleteLastProgressView];
}
- (void)didDeleteLastPart{
    [_videoModel deleteLastVideoPart];
    [_progressView deleteLastProgressView];
}


#pragma mark 写入视频数据
- (void)setUpAssetWriter{
    if(_cameraDevice.position == AVCaptureDevicePositionBack){
        AVCaptureConnection *connection =  [_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;//视频的方向
        NSLog(@"%@镜像",connection.supportsVideoMirroring?@"支持":@"不支持");
        connection.videoMirrored = NO;

        
        
    }else if(_cameraDevice.position == AVCaptureDevicePositionFront||_cameraDevice.position == AVCaptureDevicePositionUnspecified){
        AVCaptureConnection *connection = [_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo];
        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;//视频的方向
//        connection.automaticallyAdjustsVideoMirroring = YES;
        connection.videoMirrored = YES;
        NSLog(@"%@镜像",connection.supportsVideoMirroring?@"支持":@"不支持");
    }
    _assetWriter = [AVAssetWriter assetWriterWithURL:_videoModel.currentVideoPartTempFileUrl fileType:AVFileTypeQuickTimeMovie error:nil];

    int videoWidth = _videoModel.videoSize.width;
    int videoHeight = _videoModel.videoSize.height;

    NSDictionary *outputSettings = @{
                                     AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoWidthKey : @(videoHeight),
                                     AVVideoHeightKey : @(videoWidth),
                                     AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                     };
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    
    NSDictionary *audioOutputSettings = @{
                                          AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey:@(64000),
                                          AVSampleRateKey:@(44100),
                                          AVNumberOfChannelsKey:@(1),
                                          };
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    NSDictionary *SPBADictionary = @{
                                     (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (__bridge NSString *)kCVPixelBufferWidthKey : @(videoWidth),
                                     (__bridge NSString *)kCVPixelBufferHeightKey  : @(videoHeight),
                                     (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                                     };
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:SPBADictionary];
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
   
        if (!_isRecording){
            [_progressView pauseProgress];
            
            return;
        }
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        if (_assetWriter.status != AVAssetWriterStatusWriting) {
            _startRecordTime = _currentSampleTime;
            _previousFrameTime = _currentSampleTime;
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:_startRecordTime];
        }

        if (captureOutput == _videoDataOutPut) {
            if (_assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData) {
                
                //pending buffer
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                BOOL pendingResult = [_assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:_currentSampleTime];
              
                if (pendingResult) {
                    //update progressBar
                    CGFloat prgoress = CMTimeGetSeconds(CMTimeSubtract(_currentSampleTime, _startRecordTime))/_videoModel.maxRecordTime;
                    [_progressView updateProgressWithValue:prgoress];
                    
                    //update record duration
                    CGFloat newSecs = CMTimeGetSeconds(CMTimeSubtract(_currentSampleTime, _previousFrameTime));
                    CGFloat originSecs = CMTimeGetSeconds(_videoModel.duration);
                    CMTime newDuration = CMTimeMakeWithSeconds(newSecs+originSecs, _currentSampleTime.timescale);
                    _videoModel.duration = newDuration;
                    
//                    NSLog(@"videoModel.duration %f",CMTimeGetSeconds(_videoModel.duration));
                    //finish record with TimeOut
                    if(CMTimeGetSeconds(_videoModel.duration) >= _videoModel.maxRecordTime){
                        [self finishVideoWithTimeOut];
                    }
                    _previousFrameTime = _currentSampleTime;
                }else{
                    NSLog(@"Pixel Buffer Appending Failed");
                }
            }
        }
        if (captureOutput == _audioDataOutPut) {
            if(_assetWriterAudioInput.isReadyForMoreMediaData){
                [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            }
        }
    }
}

@end
