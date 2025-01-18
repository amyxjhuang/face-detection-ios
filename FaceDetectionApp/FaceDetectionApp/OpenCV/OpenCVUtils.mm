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

@implementation OpenCVUtils

+ (cv::Mat)convertImageBufferToBGRMat:(CVImageBufferRef)imageBuffer {
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
        yuvMat.release();
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

    // Detect faces
    std::vector<cv::Rect> faces;
    float scaleFactor = 1.2;
    int minNeighbors = 6;
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

+ (UIImage *)UIImageFromRGBMat:(cv::Mat)cvMat
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

@end
