# Face Detection iOS

## Install OpenCV using Cocoapods 
`sudo gem install cocoapods`
Navigate inside your XCode project directory, and run
`pod init && open Podfile`

inside the Podfile, add pod ‘OpenCV’

`pod install`
Now make sure to open the <project>.xcworkspace file from now on (instead of .xcodeproj)

Alternatively you can download the iOS pack OpenCV — 4.10.0 from https://opencv.org/releases/ and add it to your Swift project.

## Haarcascades 
This project uses frontalface_default, downloaded from https://github.com/opencv/opencv/blob/master/data/haarcascades/haarcascade_frontalface_default.xml 

