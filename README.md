# Face & Hand Detection iOS
A swift app that streams the front camera of your iOS device and draws a green rectangle around the detected faces 

<img src='https://github.com/user-attachments/assets/943a580e-72fc-42fd-99f7-2b95c2e31ffd' height='200' />

---

To use Swift we need to create a bridging header, and make sure the build settings of the project are configured to compile C++ / have C++ libraries since OpenCV methods need C++. 

In our app we receive video frames in the form of `CMSampleBuffer` (https://developer.apple.com/documentation/coremedia/cmsamplebuffer) objects. These have pixel buffers that have the format of `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`, so the buffer is separated into 2 planes, Y and UV. We have to stack the planes on top of each other, with the Y plane of size (height, width), before the UV plane of size (height/2, width/2), for the NV12 format that `cv::cvtColor` uses. 

```
        // Create cv::Mat wrappers for the Y and UV planes
        cv::Mat yMat(height, width, CV_8UC1, yPlane, yStride);
        cv::Mat uvMat(height / 2, width / 2, CV_8UC2, uvPlane, uvStride);

        // Combine Y and UV planes into a single Mat
        cv::Mat yuvMat;
        cv::vconcat(yMat, uvMat.reshape(1, height / 2), yuvMat);
```

We display the resulting video by converting the `cv::Mat` to a UIImage object, which uses RGB format. 

---
### Install OpenCV using Cocoapods 
`sudo gem install cocoapods`
Navigate inside your XCode project directory, and run
`pod init && open Podfile`

inside the Podfile, add pod ‘OpenCV’

`pod install`
Now make sure to open the <project>.xcworkspace file from now on (instead of .xcodeproj)

Alternatively you can download the iOS pack OpenCV — 4.10.0 from https://opencv.org/releases/ and add it to your Swift project.

Note: Make sure you import the opencv2 files before any other import statements, or else XCode will complain. Also make sure your build settings are configured properly to compile C++


### Haarcascades 
This project uses frontalface_default, downloaded from https://github.com/opencv/opencv/blob/master/data/haarcascades/haarcascade_frontalface_default.xml 


## Sources
- https://medium.com/@hdpoorna/integrating-opencv-to-your-swift-ios-project-in-xcode-and-working-with-uiimages-4c614e62ac88
- https://stackoverflow.com/a/20805153
- https://gist.github.com/ttruongatl/bb6c69659c48bac67826be7368560216
- 
