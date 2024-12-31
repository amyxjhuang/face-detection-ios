//
//  ViewController.swift
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//


import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate  {
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemPink

        // Setup Capture Session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high // video quality
        
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
        
//        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        videoPreviewLayer.videoGravity = .resizeAspect
//        videoPreviewLayer.frame = view.layer.bounds
        
        // Initialize imageView for processed image
        imageView = UIImageView(frame: view.bounds)
//        imageView.contentMode = .scaleAspectFit // To ensure the processed image fits within the screen
        imageView.isHidden = false // Ensure the imageView is visible
//        imageView.layer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1)) // Flip
        view.addSubview(imageView)


        // Receive video frames as sample buffers
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    // Part of the AVCaptureVideoDataOutputSampleBufferDelegate protocol
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processImageWithOpenCV(sampleBuffer: sampleBuffer)
    }

    func processImageWithOpenCV(sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

//        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) // Locks the pixel buffer
        let mat = OpenCVUtils.convertImageBuffer(toMat: imageBuffer);
        
        let processedMat = OpenCVUtils.detectFaces(in: mat)
        let processedImage = OpenCVUtils.uiImage(fromCVMat: processedMat);
        

//        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        DispatchQueue.main.async {
            if let imageView = self.imageView {
                imageView.image = processedImage
            } else {
                print("imageView is nil")
            }
        }

    }
}
