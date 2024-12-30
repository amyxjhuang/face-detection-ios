//
//  OpenCVUtils.h
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//
#include <opencv2/core.hpp>  // For cv::Mat

#include <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVUtils : NSObject

+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;
+ (cv::Mat)convertPixelBufferToMat:(CVPixelBufferRef)pixelBuffer; // Use 'id' for opaque C++ object, since we can only import the opencv functions in .mm files
+ (cv::Mat)detectFacesInMat:(cv::Mat)inputMat;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat)convertImageBufferToMat:(CVImageBufferRef)imageBuffer;
@end

