//
//  ViewController.m
//  人脸识别
//
//  Created by rayootech on 16/4/18.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger,ZWViewType){
   ZWViewType_eyes,
   ZWViewType_mouth
};

//设置颜色
#define ZWEyesColor [UIColor blueColor]
#define ZWMouthColor [UIColor greenColor]
//设置图层大小比例
#define ZWEyesScale 0.2
#define ZWMouthScale 0.4

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    UIImage* image = [UIImage imageNamed:@"person.png"];
    image = [self strectImageWithImage:image targetSize:CGSizeMake(200, 200)];
    UIImageView *imageV = [[UIImageView alloc] initWithImage: image];
    [imageV setFrame:CGRectMake(0, 0, image.size.width,image.size.height)];
    imageV.center = self.view.center;
    [self.view addSubview:imageV];
    
    [self drawFaceWithImageView:imageV];
    
}


#pragma mark-放大图片
-(UIImage *)strectImageWithImage:(UIImage *)image targetSize:(CGSize)size{
  
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = CGPointMake(0, 0);
    thumbnailRect.size.width  = size.width;
    thumbnailRect.size.height = size.height;
    [image drawInRect:thumbnailRect];
    
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (newImage) {
        return  newImage;
    }
    return nil;
}

#pragma mark-进行人脸识别
-(void)drawFaceWithImageView:(UIImageView *)imageView{
    
    CIImage* ciimage = [CIImage imageWithCGImage:imageView.image.CGImage];
    NSDictionary* opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:opts];
    //所有的人脸数据
    NSArray* features = [detector featuresInImage:ciimage];
    
    //得到图片的尺寸
    CGSize inputImageSize = [ciimage extent].size;
    //初始化transform
    CGAffineTransform  transform = CGAffineTransformIdentity;
    //设置缩放，
    transform = CGAffineTransformScale(transform, 1, -1);
    //将图片上移
    transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height);
    
    for (CIFaceFeature *faceFeature in features){
        //获取人脸的frame
        CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        //获取人脸范围的宽
        CGFloat faceWidth = faceFeature.bounds.size.width;
        //描绘人脸区域
        UIView* faceView = [[UIView alloc] initWithFrame:faceViewBounds];
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        [imageView addSubview:faceView];
        
        if(faceFeature.hasLeftEyePosition){
            //获取人左眼对应的point
            CGPoint faceViewLeftPoint = CGPointApplyAffineTransform(faceFeature.leftEyePosition, transform);
            //添加遮罩
            [imageView addSubview:[self createCoverViewWithPoint:faceViewLeftPoint andWith:faceWidth andType:ZWViewType_eyes]];
        }
        
        if(faceFeature.hasRightEyePosition){
            //获取人右眼对应的point
            CGPoint faceViewRightPoint = CGPointApplyAffineTransform(faceFeature.rightEyePosition, transform);
            //添加遮罩
            [imageView addSubview:[self createCoverViewWithPoint:faceViewRightPoint andWith:faceWidth andType:ZWViewType_eyes]];
        }
        
        if(faceFeature.hasMouthPosition){
            //获取人嘴巴对应的point
            CGPoint faceViewMouthPoint = CGPointApplyAffineTransform(faceFeature.mouthPosition, transform);
            //添加遮罩
            [imageView addSubview:[self createCoverViewWithPoint:faceViewMouthPoint andWith:faceWidth andType:ZWViewType_mouth]];
        }         
        
    }  
}

#pragma mark-绘制遮罩
-(UIView *)createCoverViewWithPoint:(CGPoint)point andWith:(CGFloat)width andType:(ZWViewType)type{
    
    CGFloat newWidth = 0;
    UIColor *color = nil;
    switch (type) {
        case ZWViewType_eyes:
            newWidth = width * ZWEyesScale;
            color= ZWEyesColor;
            break;
        case ZWViewType_mouth:
            newWidth = width * ZWMouthScale;
            color= ZWMouthColor;
            break;
        default:
            break;
    }
    UIView* cover = [[UIView alloc] initWithFrame:
                     CGRectMake( 0, 0, newWidth, newWidth)];
    [cover setBackgroundColor:[color colorWithAlphaComponent:0.3]];
    [cover setCenter:point];
    cover.layer.cornerRadius = newWidth/2;
    return  cover;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
