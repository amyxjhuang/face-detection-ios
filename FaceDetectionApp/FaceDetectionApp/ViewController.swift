//
//  ViewController.swift
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemPink

        // Setup Capture Session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No camera available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error accessing camera: \(error)")
            return
        }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.frame = view.layer.bounds
        
        videoPreviewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1)) // Horizontal flip

        view.layer.addSublayer(videoPreviewLayer)

        // Receive video frames as sample buffers
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)

        captureSession.startRunning()
    }

    // Process Each Frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Pass pixelBuffer to OpenCV for processing
        processImageWithOpenCV(pixelBuffer)
    }

    func processImageWithOpenCV(_ pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
           
       let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
       let width = CVPixelBufferGetWidth(pixelBuffer)
       let height = CVPixelBufferGetHeight(pixelBuffer)
       let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
       
       // Assuming a BGRA pixel format
       let mat = cv::Mat(
           rows: height,
           cols: width,
           type: cv.CV_8UC4,
           data: baseAddress
       )
       
       CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
       
    }
}
