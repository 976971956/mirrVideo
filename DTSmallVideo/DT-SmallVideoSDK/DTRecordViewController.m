//
//  RecordViewController.m
//  DTSmallVideo
//
//  Created by quan cui on 2016/12/15.
//  Copyright © 2016年 quan cui. All rights reserved.
//

#import "DTRecordViewController.h"
#import "SmallVideoHeader.h"
#define kNavButtonWidth 30
#define kNavButtonPadding 11
#define kRecordButtonHeight 80
typedef NS_ENUM(NSInteger, DTCameraFlashType) {
    DTCameraFlashAUTO = 0,
    DTCameraFlashOPEN = 1,
    DTCameraFlashCLOSE = 2
};

@interface DTRecordViewController ()
{
    NSTimer *timer;
    int times;
}
@property (nonatomic, strong) UIView *navigationView;
@property (nonatomic, strong) UIButton *buttonBack;
@property (nonatomic, strong) UIButton *buttonCameraSwitch;
@property (nonatomic, strong) UIButton *buttonFlash;

@property (nonatomic, strong) DTRecordView *recordView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *buttonRecord;
@property (nonatomic, strong) UIButton *buttonComplete;

@property (nonatomic, strong) UIButton *buttonBackWard;
@property (nonatomic, strong) UIButton *buttonDelete;
@property (nonatomic, strong) UIButton *buttonReset;
@property (nonatomic, strong) UIButton *buttonImagealbum;
@property (nonatomic, strong) UIButton *buttonPhoto;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@end

@implementation DTRecordViewController{
    
}
- (instancetype)initRecorViewControllerWithCompleteBlock:(DTRecordCompleteBlock)completeBlock{
    if(self == [super init]){
        self.completeBlock = completeBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor yellowColor];
    [self setUpNavigationToolBar];
    [self setUpCameraView];
    [self setUPBottomView];
}
- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:YES];
}
- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:NO];
}
#pragma mark - UI Building -
-(void)setUpNavigationToolBar{
    // topView
    self.navigationView = [[UIView alloc] initWithFrame:(CGRectMake(0, 0, kScreenWidth, 43.5+20))];
    self.navigationView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.navigationView];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 20, kScreenWidth-200, 44)];
    titleLabel.text = @"视频";
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:18];
    [self.navigationView addSubview:titleLabel];
    
    self.buttonBack = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonBack.frame = CGRectMake(kNavButtonPadding, 20+43/2-15, 40, 30);
    self.buttonBack.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.buttonBack setTitleColor:[UIColor blackColor] forState:0];
    [self.buttonBack addTarget:self action:@selector(navigationViewButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.buttonBack setTitle:@"取消" forState:0];
//   [self.buttonBack setImage:[UIImage imageNamed:@"icon_back"] forState:(UIControlStateNormal)];
    [self.navigationView addSubview:self.buttonBack];
    
    self.buttonComplete = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonComplete.frame = CGRectMake(CGRectGetWidth(self.navigationView.frame)-11-11-36, 20, 58, 44);
    [self.buttonComplete setTitleColor:[UIColor blackColor] forState:0];
    [self.buttonComplete setTitle:@"完成" forState:0];
    //    [self.buttonComplete setImage:[UIImage imageNamed:@"icon_complete"] forState:(UIControlStateNormal)];
    [self.buttonComplete addTarget:self action:@selector(completeButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.navigationView addSubview:self.buttonComplete];
}
- (void)setUpCameraView{
    
    self.recordView = [[DTRecordView alloc]initWithFrame:CGRectMake(0, self.navigationView.frame.size.height, kScreenWidth, kScreenWidth)];
    [self.view addSubview:self.recordView];
    [self addObserver:self forKeyPath:@"self.recordView.recordState" options:NSKeyValueObservingOptionNew context:nil];
    
    self.buttonCameraSwitch = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonCameraSwitch.frame = CGRectMake(18, CGRectGetHeight(self.recordView.frame)-18.5-20.5, 20.5, 20.5);
    [self.buttonCameraSwitch setImage:[UIImage imageNamed:@"翻转摄像头"] forState:(UIControlStateNormal)];
    [self.buttonCameraSwitch setImage:[UIImage imageNamed:@"翻转摄像头"] forState:(UIControlStateSelected)];
    [self.buttonCameraSwitch addTarget:self action:@selector(navigationViewButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.recordView addSubview:self.buttonCameraSwitch];
    
    self.buttonFlash = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonFlash.frame = CGRectMake(CGRectGetWidth(self.recordView.frame)-16-23.5, CGRectGetHeight(self.recordView.frame)-17-23.5, 23.5, 23.5);
    [self.buttonFlash setImage:[UIImage imageNamed:@"闪关灯"] forState:(UIControlStateNormal)];
    [self.buttonFlash addTarget:self action:@selector(navigationViewButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.recordView addSubview:self.buttonFlash];
}
- (void)setUPBottomView{
    
    self.bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, self.recordView.frame.origin.y + self.recordView.frame.size.height, kScreenWidth, kScreenHeight - self.navigationView.frame.size.height - self.recordView.frame.size.height)];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomView];
    
    self.buttonRecord = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonRecord.frame = CGRectMake(self.bottomView.frame.size.width/2-kRecordButtonHeight/2, self.bottomView.frame.size.height/2-kRecordButtonHeight/2, kRecordButtonHeight, kRecordButtonHeight);
    [self.buttonRecord setImage:[UIImage imageNamed:@"小视频按钮"] forState:(UIControlStateNormal)];
    [self.buttonRecord setImage:[UIImage imageNamed:@"小视频按钮"] forState:(UIControlStateDisabled)];

    [self.buttonRecord addTarget:self action:@selector(recordButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.buttonRecord addTarget:self action:@selector(recordButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];

    [self.bottomView addSubview:self.buttonRecord];
    //相册
    self.buttonImagealbum = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonImagealbum.frame = CGRectMake(18, 19.5, 23.5, 23.5);
    [self.buttonImagealbum setImage:[UIImage imageNamed:@"图片"] forState:(UIControlStateNormal)];
    [self.buttonImagealbum setImage:[UIImage imageNamed:@"图片按下"] forState:(UIControlStateHighlighted)];
    [self.buttonImagealbum addTarget:self action:@selector(ImagealbumButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.bottomView addSubview:self.buttonImagealbum];
//拍照
    self.buttonPhoto = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonPhoto.frame = CGRectMake(kScreenWidth-16.5-28, 20.5, 24.5, 21.5);
    [self.buttonPhoto setImage:[UIImage imageNamed:@"拍照"] forState:(UIControlStateNormal)];
    [self.buttonPhoto setImage:[UIImage imageNamed:@"拍照按下"] forState:(UIControlStateHighlighted)];
    [self.buttonPhoto addTarget:self action:@selector(PhotoButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.bottomView addSubview:self.buttonPhoto];
    
    self.buttonBackWard = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonBackWard.frame = CGRectMake(kNavButtonPadding*5, self.bottomView.frame.size.height/2-kNavButtonWidth/2, kNavButtonWidth, kNavButtonWidth);
    [self.buttonBackWard setImage:[UIImage imageNamed:@"icon_backward"] forState:(UIControlStateNormal)];
    [self.buttonBackWard addTarget:self action:@selector(backwardButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.bottomView addSubview:self.buttonBackWard];
    
    self.buttonDelete = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.buttonDelete setTitleColor:[UIColor blackColor] forState:0];
    self.buttonDelete.frame = CGRectMake(kScreenWidth/2-50, CGRectGetHeight(self.bottomView.frame)-9.5-33.5, 100, 33.5);
    [self.buttonDelete setTitle:@"删除" forState:0];
//    [self.buttonDelete setImage:[UIImage imageNamed:@"icon_delete"] forState:(UIControlStateNormal)];
    [self.buttonDelete addTarget:self action:@selector(deleteLastPartButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    self.buttonDelete.hidden = YES;
    [self.bottomView addSubview:self.buttonDelete];
    
    self.buttonReset = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.buttonReset.frame = CGRectMake(kScreenWidth/2-50, CGRectGetHeight(self.bottomView.frame)-9.5-33.5, 100, 33.5);
    self.buttonReset.titleLabel.font = [UIFont systemFontOfSize:13];
    
    [self.buttonReset setTitleColor:[UIColor blackColor] forState:0];
    
    [self.buttonReset setTitle:@"删除" forState:0];
    
//    [self.buttonReset setImage:[UIImage imageNamed:@"icon_restart"] forState:(UIControlStateNormal)];
    [self.buttonReset addTarget:self action:@selector(resetButtonClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    self.buttonReset.hidden = YES;
    [self.bottomView addSubview:self.buttonReset];
    
}
#pragma mark - RecordView state observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

    if ([keyPath isEqualToString:@"self.recordView.recordState"]) {
        [self updateRecordController];
    }
}
-(void)timerAction
{
    times++;
    NSLog(@"%d",times);
}
-(void)updateRecordController{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.recordView.recordState == DTRecordStateInit){

            self.buttonFlash.enabled = YES;
            self.buttonCameraSwitch.enabled = YES;
            
            self.buttonBackWard.enabled = YES;
            self.buttonBackWard.hidden = NO;
            self.buttonDelete.hidden = YES;
            self.buttonReset.hidden = YES;
            self.buttonRecord.enabled = YES;
            self.buttonRecord.hidden = NO;
            [self.buttonComplete setTitle:@"完成" forState:0];
            
        }else if(self.recordView.recordState == DTRecordStateRecording){


            [self.indicator stopAnimating];
            
            self.buttonFlash.enabled = NO;
            self.buttonCameraSwitch.enabled = YES;
            
            self.buttonBackWard.enabled = NO;
            self.buttonBackWard.hidden = NO;
            self.buttonDelete.hidden = YES;
            
            self.buttonRecord.enabled = YES;
            self.buttonRecord.hidden = NO;
            
            self.buttonComplete.enabled = NO;
            
        }else if(self.recordView.recordState == DTRecordStatePause){
//            暂停
            [timer setFireDate:[NSDate distantFuture]];
            
            self.buttonFlash.enabled = YES;
            self.buttonCameraSwitch.enabled = YES;
            
            [self.indicator stopAnimating];
            
            self.buttonDelete.hidden = YES;

            self.buttonRecord.enabled = YES;
            self.buttonRecord.hidden = NO;
            
            self.buttonBackWard.enabled = YES;
            self.buttonComplete.enabled = YES;
            if (times<3) {
                NSLog(@"%d",times);
                self.buttonBackWard.hidden = NO;
                [self.recordView didDeleteLastPart];
                
            }else{
                NSLog(@"%d",times);
                [self.recordView finishVideoRecord];

            }


        }else if(self.recordView.recordState == DTRecordStateCombining){
//            完成
            //            暂停
            [timer setFireDate:[NSDate distantFuture]];
            
            self.buttonFlash.enabled = NO;
            self.buttonCameraSwitch.enabled = YES;
            [self.indicator startAnimating];
            
            self.buttonRecord.enabled = NO;
            self.buttonRecord.hidden = NO;
            self.buttonBackWard.hidden = YES;
            self.buttonDelete.hidden = YES;
            
            self.buttonReset.hidden = NO;
            self.buttonReset.enabled = NO;
            self.buttonComplete.enabled = NO;
            
        }else if(self.recordView.recordState == DTRecordStateRePlay){
            self.buttonFlash.enabled = NO;
            self.buttonCameraSwitch.enabled = YES;
            [self.indicator stopAnimating];
            
            self.buttonBackWard.hidden = YES;
            self.buttonDelete.hidden = YES;
            self.buttonReset.enabled = YES;
            self.buttonComplete.enabled = YES;
            [self.buttonComplete setTitle:@"继续" forState:0];

//            [self.buttonComplete setImage:[UIImage imageNamed:@"icon_save.png"] forState:(UIControlStateNormal)];
        }
    });
}
#pragma mark - View Action -
- (void)navigationViewButtonAction:(UIButton *)sender{
    if ( [sender isEqual:self.buttonBack]) {
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    if ( [sender isEqual:self.buttonCameraSwitch]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.recordView switchCamera];
            
        });
    }
    if ( [sender isEqual:self.buttonFlash]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recordView switchTorch];
            if(self.recordView.torchType == DTTorchClose){
                [self.buttonFlash setImage:[UIImage imageNamed:@"闪关灯"] forState:(UIControlStateNormal)];
            }else if(self.recordView.torchType == DTTorchOpen){
                [self.buttonFlash setImage:[UIImage imageNamed:@"开闪光灯"] forState:(UIControlStateNormal)];
            }else if(self.recordView.torchType == DTTorchAuto){
                [self.buttonFlash setImage:[UIImage imageNamed:@"开闪光灯"] forState:(UIControlStateNormal)];
            }
        });
    }
}
- (void)recordButtonTouchDown:(UIButton *)sender{
    if(self.recordView.recordState == DTRecordStateInit || self.recordView.recordState == DTRecordStatePause){
        times = 0;
        if (!timer) {
            timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
        [timer setFireDate:[NSDate distantPast]];
        [self.recordView startRecord];
        return;
    }
}
- (void)recordButtonTouchUp:(UIButton *)sender{
    if(self.recordView.recordState != DTRecordStateRecording){
        return;
    }else{
        
        [self.recordView pauseRecord];
    }
}
- (void)completeButtonClicked:(UIButton *)sender{
    if(self.recordView.recordState == DTRecordStateRePlay){
        self.completeBlock(self.recordView.videoModel.videoExportUrl);
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self.recordView finishVideoRecord];
    }
}
//相册
-(void)ImagealbumButtonClicked:(UIButton *)sender
{
    
}
//拍照
-(void)PhotoButtonClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)backwardButtonClicked:(UIButton *)sender{
    self.buttonBackWard.hidden = YES;
    self.buttonDelete.hidden = NO;
    [self.recordView selectLastDeletePart];
}
- (void)deleteLastPartButtonClicked:(UIButton *)sender{
    self.buttonBackWard.hidden = NO;
    self.buttonDelete.hidden = YES;
    [self.recordView didDeleteLastPart];
}
- (void)resetButtonClicked:(UIButton *)sender{
    [self.recordView resetRecord];
}

-(UIActivityIndicatorView *)indicator{
    if(!_indicator){
        _indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.center = CGPointMake(self.recordView.frame.size.width/2, self.recordView.frame.size.height/2+self.navigationView.frame.size.height);
        [self.view addSubview:_indicator];
        _indicator.color = kGreen;
        [_indicator setHidesWhenStopped:YES];
    }
    return _indicator;
}
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"self.recordView.recordState"];
}
@end
