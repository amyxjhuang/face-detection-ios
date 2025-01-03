//
//  OpenCVUtils.mm
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//


#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>

#import "OpenCVUtils.h"
static cv::CascadeClassifier faceCascade;
static bool isModelLoaded = false;


@interface UIImage (OpenCVUtils)
- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists;
- (cv::Mat)cvMatFromUIImage:(UIImage *)image;
- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;

@end

@implementation UIImage (OpenCVUtils)

- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists {
    if (self.imageOrientation == UIImageOrientationRight) {
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat, alphaExists);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
 
  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
 
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags
 
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
 
  return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
 
  cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
 
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags
 
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
 
  return cvMat;
 }



@end

@implementation OpenCVUtils


+ (NSString *)getOpenCVVersion {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}
 
+ (cv::Mat)convertImageBufferToMat:(CVImageBufferRef)imageBuffer {
    if (imageBuffer == NULL) {
        return cv::Mat(); // Return an empty Mat if the buffer is null
    }

    // Check if the imageBuffer is a CVPixelBufferRef
    if (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()) {

        // Convert to CVPixelBufferRef
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)imageBuffer;

        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        uint8_t* yPlane = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t* uvPlane = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

        // Create cv::Mat wrappers for the Y and UV planes
        cv::Mat yMat(height, width, CV_8UC1, yPlane, yStride);
        cv::Mat uvMat(height / 2, width / 2, CV_8UC2, uvPlane, uvStride);

        // Combine Y and UV planes into a single Mat
        cv::Mat yuvMat;
        cv::vconcat(yMat, uvMat.reshape(1, height / 2), yuvMat);

        // Convert YUV to BGR
        cv::Mat bgrMat;
        cv::cvtColor(yuvMat, bgrMat, cv::COLOR_YUV2BGR_NV12);

        cv::Mat rotatedImage;
        cv::rotate(bgrMat, rotatedImage, cv::ROTATE_90_CLOCKWISE);
        cv::Mat flippedImage;
        cv:flip(rotatedImage, flippedImage,1);
        
        yMat.release();
        uvMat.release();
        bgrMat.release();
        rotatedImage.release();
        
        return flippedImage;
    }

    return cv::Mat(); // Return an empty cv::Mat if it's not a supported type
}

+ (BOOL)loadFaceCascadeModel {
    if (!isModelLoaded) {
        NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
        if (!faceCascade.load([faceCascadePath UTF8String])) {
            NSLog(@"Error loading Haar cascade.");
            isModelLoaded = NO;
        }
        isModelLoaded = YES;
    }
    return isModelLoaded;
}

+ (cv::Mat)detectFacesInMat:(cv::Mat)inputMat {
    // Convert the inputMat from BGR to Grayscale
    cv::Mat grayMat;
    cv::cvtColor(inputMat, grayMat, cv::COLOR_BGR2GRAY);

//    // Load the Haar cascade model
//    cv::CascadeClassifier faceCascade;
//    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
//
//
//    if (!faceCascade.load([faceCascadePath UTF8String])) {
//        NSLog(@"Error loading Haar cascade.");
//        return inputMat; // Return original frame if the model fails to load
//    }

    // Detect faces
    std::vector<cv::Rect> faces;
    float scaleFactor = 1.1;
    int minNeighbors = 3;
    int flags = 0;
    faceCascade.detectMultiScale(
        grayMat,
        faces,
        scaleFactor,
        minNeighbors,
        flags,
        cv::Size(30, 30) // Minimum size
    );

    // Draw rectangles around detected faces
    for (const auto& face : faces) {
        cv::rectangle(inputMat, face, cv::Scalar(0, 255, 0), 2); // Green rectangles
    }
    cv::Mat processedRBGMat;
    cv::cvtColor(inputMat, processedRBGMat, cv::COLOR_BGR2RGB);
    
    inputMat.release();
    return processedRBGMat; // Return the modified frame
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
 
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                      kCGImageAlphaNone,
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );
 
 
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
 
  return finalImage;
 }



+ (UIImage *)grayscaleImg:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    cv::Mat gray;
    
    NSLog(@"channels = %d", mat.channels());

    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    UIImage *grayImg = MatToUIImage(gray);
    return grayImg;
}

+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    if (mat.channels() == 4) {
        [image convertToMat: &mat :true];
    }
    
    NSLog(@"source shape = (%d, %d)", mat.cols, mat.rows);
    
    cv::Mat resized;
    
//    cv::INTER_NEAREST = 0,
//    cv::INTER_LINEAR = 1,
//    cv::INTER_CUBIC = 2,
//    cv::INTER_AREA = 3,
//    cv::INTER_LANCZOS4 = 4,
//    cv::INTER_LINEAR_EXACT = 5,
//    cv::INTER_NEAREST_EXACT = 6,
//    cv::INTER_MAX = 7,
//    cv::WARP_FILL_OUTLIERS = 8,
//    cv::WARP_INVERSE_MAP = 16
    
    cv::Size size = {width, height};
    
    cv::resize(mat, resized, size, 0, 0, interpolation);
    
    NSLog(@"dst shape = (%d, %d)", resized.cols, resized.rows);
    
    UIImage *resizedImg = MatToUIImage(resized);
    
    return resizedImg;

}

@end
