//
//  OpenCVUtils.h
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//
#include <opencv2/core.hpp>
#include <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVUtils : NSObject

/* Loads the FaceCascade model from OpenCV, returns YES if it successfully loaded */
+ (BOOL)loadFaceCascadeModel;

/* Detects faces in the input mat (BGR) and draws rectangles around each face.
 * Outputs the resulting mat in RBG format */
+ (cv::Mat)detectFacesInMat:(cv::Mat)inputMat;

/* Given an image buffer, convert to a BGR format cv::Mat */
+ (cv::Mat)convertImageBufferToBGRMat:(CVImageBufferRef)imageBuffer;

/* Converts an RGB mat into a UIImage */
+ (UIImage *)UIImageFromRGBMat:(cv::Mat)cvMat;

CVPixelBufferRef pixelBufferFromMat(const cv::Mat& mat);
@end

