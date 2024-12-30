//
//  OpenCVUtils.h
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//

#include <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface OpenCVUtils : NSObject

+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;
+ (id)convertPixelBufferToMat:(CVPixelBufferRef)pixelBuffer; // Use 'id' for opaque C++ object, since we can only import the opencv functions in .mm files

@end

NS_ASSUME_NONNULL_END
