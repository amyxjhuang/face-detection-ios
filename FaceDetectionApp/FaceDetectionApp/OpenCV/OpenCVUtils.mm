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

        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

        // Get the base address of the pixel buffer
        void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);

        // Get the image dimensions and bytes per row
        int width = CVPixelBufferGetWidth(pixelBuffer);
        int height = CVPixelBufferGetHeight(pixelBuffer);
        int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

        // Check the pixel format and create the corresponding cv::Mat
        cv::Mat mat;

        // If the pixel format is BGRA (32-bit color), handle as such
        if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA) {
            mat = cv::Mat(height, width, CV_8UC4, baseAddress, bytesPerRow);
        }
        // If it's YUV420p, we need to convert it manually to RGB or BGRA
        else if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
            // The Y plane starts at baseAddress, followed by the UV plane
            uint8_t *yPlane = (uint8_t *)baseAddress;
            uint8_t *uvPlane = yPlane + width * height;
            NSLog(@"Pixel format: %ld", CVPixelBufferGetPixelFormatType(pixelBuffer));
            NSLog(@"Base address: %p", baseAddress);
            NSLog(@"Width: %d, Height: %d, BytesPerRow: %d", width, height, bytesPerRow);

    
            NSLog(@"First pixel in Y plane: %d", yPlane[0]);  // Print first Y pixel value

            // Create OpenCV matrices for the Y, U, and V planes
            cv::Mat yMat(height, width, CV_8UC1, yPlane);
            cv::Mat uvMat(height / 2, width / 2, CV_8UC2, uvPlane);

            // You need to convert the YUV to RGB/BGRA
            cv::Mat rgbMat;
            cv::cvtColor(yMat, rgbMat, cv::COLOR_YUV2BGR_I420);

            // Optionally, convert to BGRA (if you need a 4-channel output)
            cv::Mat bgraMat;
            cv::cvtColor(rgbMat, bgraMat, cv::COLOR_BGR2BGRA);

            mat = bgraMat;
        }

        // Unlock the base address after processing
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

        return mat;
    }

    // If it's not a CVPixelBufferRef, you can return an empty Mat or handle it differently
    return cv::Mat(); // Return an empty cv::Mat if it's not a supported type
}

+ (cv::Mat)convertPixelBufferToMat:(CVPixelBufferRef)pixelBuffer {
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    // Get the base address of the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    int width = CVPixelBufferGetWidth(pixelBuffer);
    int height = CVPixelBufferGetHeight(pixelBuffer);
    int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

    // Create the OpenCV Mat with the appropriate data and dimensions
    cv::Mat mat(height, width, CV_8UC1, baseAddress, bytesPerRow);

    // Unlock the base address
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    // Return the resulting cv::Mat
    return mat;
}


+ (cv::Mat)detectFacesInMat:(cv::Mat)inputMat {
    // Convert the inputMat from BGRA to Grayscale
    cv::Mat grayMat;
    cv::cvtColor(inputMat, grayMat, cv::COLOR_BGRA2GRAY);

    // Load the Haar cascade model
    cv::CascadeClassifier faceCascade;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];


    if (!faceCascade.load([faceCascadePath UTF8String])) {
        NSLog(@"Error loading Haar cascade.");
        return inputMat; // Return original frame if the model fails to load
    }

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

    return inputMat; // Return the modified frame
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
 
  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }
 
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
 
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                      kCGImageAlphaNoneSkipLast,// bitmap info
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
