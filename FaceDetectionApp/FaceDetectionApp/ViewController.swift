//
//  ViewController.swift
//  FaceDetectionApp
//
//  Created by Amy Huang on 12/19/24.
//


import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate  {
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var imageView: UIImageView!
    var recordButton: UIButton!
    var movieFileOutput: AVCaptureMovieFileOutput!
    var didEnableVideoPermissions: Bool!
    var didEnableAudioPermissions: Bool!
    
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?


    override func viewDidLoad() {
        super.viewDidLoad()
        if !OpenCVUtils.loadFaceCascadeModel() {
            NSLog("Could not load FaceCascade model")
            return
        }
        NSLog("Succesfully loaded FaceCascade model")

        didEnableVideoPermissions = false
        didEnableAudioPermissions = false
        self.view.backgroundColor = UIColor.systemPink
        
        // Setup Capture Session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .low // video quality

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
        
        imageView = UIImageView(frame: view.bounds)
        imageView.isHidden = false // Ensure the imageView is visible
        view.addSubview(imageView)


        // Receive video frames as sample buffers
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.connection(with: .video)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        
        AVCaptureDevice.requestAccess(for: .video) { grantedVideo in
            NSLog("Granted video access \(grantedVideo)")
            self.didEnableVideoPermissions = grantedVideo

        }
        
        AVCaptureDevice.requestAccess(for: .audio) { grantedAudio in
            NSLog("Granted audio access \(grantedAudio)")
            self.didEnableAudioPermissions = grantedAudio
        }
        if (didEnableAudioPermissions && didEnableVideoPermissions) {
            self.setupUI()
            movieFileOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(movieFileOutput) {
                captureSession.addOutput(movieFileOutput)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    func setupUI() {
        recordButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 80, width: 100, height: 50))
        recordButton.backgroundColor = .red
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        view.addSubview(recordButton)
    }


    // Part of the AVCaptureVideoDataOutputSampleBufferDelegate protocol
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processImageWithOpenCV(sampleBuffer: sampleBuffer)
    }

    func processImageWithOpenCV(sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) // Locks the pixel buffer
        
        var bgrMat = OpenCVUtils.convertImageBuffer(toBGRMat: imageBuffer);
        var processedMat = OpenCVUtils.detectFaces(in: bgrMat)
        let processedImage = OpenCVUtils.uiImage(fromRGBMat: processedMat);
        
        bgrMat.release()
        processedMat.release()

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        DispatchQueue.main.async {
            if let imageView = self.imageView {
                imageView.image = processedImage
            } else {
                print("imageView is nil")
            }
        }

    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        
        if let error = error {
            print("Recording failed: \(error.localizedDescription)")
        } else {
            print("Video recorded successfully at: \(outputFileURL)")
            // You can now do something with the recorded video,
            // like save it to the Photos library or play it back.
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path(), nil, nil, nil);
        }
    }
    
    
    @objc func toggleRecording() {
        if movieFileOutput.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        // Create a temporary file URL for saving the video.
        let outputPath = NSTemporaryDirectory() + "output-\(UUID().uuidString).mov"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Remove file if it already exists (unlikely in this case).
//        if FileManager.default.fileExists(atPath: outputPath) {
//            try? FileManager.default.removeItem(atPath: outputPath)
//        }
        
        // Start recording to this URL
        movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
        recordButton.setTitle("Stop", for: .normal)
    }
    
    func stopRecording() {
        movieFileOutput.stopRecording()
        recordButton.setTitle("Record", for: .normal)
    }

}
