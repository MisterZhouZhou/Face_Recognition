//
//  ViewController.m
//  人脸识别例子2
//
//  Created by rayootech on 16/4/19.
//  Copyright © 2016年 rayootech. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

/*注释*/
@property(nonatomic,strong)UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"person"];
    self.imageView =[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    self.imageView.center = self.view.center;
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    self.imageView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.imageView];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self loadImage];
}

#pragma mark - ibaction
- (void)loadImage {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                            delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                            otherButtonTitles:@"相册", @"拍照", @"默认目录", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    [actionSheet showInView:self.view];

}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 2) {
        return;
    }
    else if(buttonIndex !=2){
        //从相册或者拍照拿到照片
        UIImagePickerControllerSourceType sourceType = (buttonIndex == 0)?UIImagePickerControllerSourceTypePhotoLibrary:UIImagePickerControllerSourceTypeCamera;
        
        if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = sourceType;
            picker.delegate = self;
            picker.allowsEditing = NO;
            [self presentModalViewController:picker animated:YES];
          
        }
    }
    else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"person" ofType:@"png"];
        _imageView.image = [UIImage imageWithContentsOfFile:path];
        
        [self dealImageWhenItChanged];//人脸识别去
    }
    
    
}


#pragma mark UIImagePickerControllerDelegate
//对图片方向进行校正
- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    static int kMaxResolution = 640;
    
    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        } else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    //处理图片旋转
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    _imageView.image = [self scaleAndRotateImage:image];
    _imageView.frame = CGRectMake(0, 0, _imageView.image.size.width, _imageView.image.size.height);
    _imageView.center = self.view.center;
    [self dealImageWhenItChanged];//人脸识别去
    
    [picker dismissModalViewControllerAnimated:YES];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}


#pragma mark-移除所有的标记
-(void)removeAllMarkViews
{
    //清除原来标记的View
    for (UIView *vv in self.imageView.subviews) {
        if (vv.tag == 111) {
            [vv removeFromSuperview];
        }
    }
}

#pragma mark - 人脸识别
-(void)dealImageWhenItChanged
{
    [self removeAllMarkViews];
    self.imageView.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self faceDetect:_imageView.image];
    });
    
    
}


#pragma mark - 人脸检测方法
- (void)faceDetect:(UIImage *)aImage
{
    
    //Create a CIImage version of your photo
    CIImage* image = [CIImage imageWithCGImage:aImage.CGImage];
    
    //create a face detector
    //此处是CIDetectorAccuracyHigh，若用于real-time的人脸检测，则用CIDetectorAccuracyLow，更快
    NSDictionary  *opts = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                      forKey:CIDetectorAccuracy];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:opts];
    
    //Pull out the features of the face and loop through them
    NSArray* features = [detector featuresInImage:image];
    if (features) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self markAfterFaceDetect:features];
        });
    }
    
}

//人脸标识
-(void)markAfterFaceDetect:(NSArray *)features
{
    if ([features count]==0) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Failed"
                                                       message:@"The face detecting failed"
                                                      delegate:self
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    for (CIFaceFeature *f in features)
    {
        //旋转180，仅y
        CGRect aRect = f.bounds;
        aRect.origin.y = self.imageView.bounds.size.height - aRect.size.height - aRect.origin.y;//
        
        UIView *vv = [[UIView alloc]initWithFrame:aRect];
        vv.backgroundColor = [UIColor redColor];
        vv.tag = 111;
        vv.alpha = 0.6;
        [self.imageView addSubview:vv];
    
        if (f.hasLeftEyePosition){
 
            UIView *vv = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
            
            //旋转180，仅y
            CGPoint newCenter =  f.leftEyePosition;
            newCenter.y = self.imageView.bounds.size.height-newCenter.y;
            vv.center = newCenter;
            vv.tag = 111;
            vv.backgroundColor = [UIColor blueColor];
            vv.alpha = 0.6;
            [self.imageView addSubview:vv];
           
        }
        if (f.hasRightEyePosition)
        {
            printf("Right eye %g %g\n", f.rightEyePosition.x, f.rightEyePosition.y);
            
            UIView *vv = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
            //旋转180，仅y
            CGPoint newCenter =  f.rightEyePosition;
            newCenter.y = self.imageView.bounds.size.height-newCenter.y;
            vv.center = newCenter;
            vv.tag = 111;
            vv.backgroundColor = [UIColor blueColor];
            vv.alpha = 0.6;
            [self.imageView addSubview:vv];
          
        }
        if (f.hasMouthPosition)
        {

            UIView *vv = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
            //旋转180，仅y
            CGPoint newCenter =  f.mouthPosition;
            newCenter.y = self.imageView.bounds.size.height-newCenter.y;
            vv.center = newCenter;
            vv.tag = 111;
            vv.backgroundColor = [UIColor greenColor];
            vv.alpha = 0.6;
            [self.imageView addSubview:vv];
            
        }
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
