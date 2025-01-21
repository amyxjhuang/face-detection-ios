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
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor!
    var isRecording: Bool = false


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
        captureSession.sessionPreset = .medium // video quality

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

    
    @objc func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            if setupAssetWriter() {
                startRecording()
            }
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

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

        // Process the image using OpenCV
        let bgrMat = OpenCVUtils.convertImageBuffer(toBGRMat: imageBuffer)
        let processedMat = OpenCVUtils.detectFaces(in: bgrMat)
        let processedImage = OpenCVUtils.uiImage(fromRGBMat: processedMat)

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        DispatchQueue.main.async {
            self.imageView?.image = processedImage
        }

        // Write to video if recording
        if isRecording {
            if (assetWriter?.status == .unknown) {
                // Check that the asset writer started writing
                assetWriter?.startWriting()
                assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
            let unmanagedPixelBuffer = getImageBufferFromMat(processedMat)
            let pixelBuffer = unmanagedPixelBuffer?.takeRetainedValue()

            if let pixelBuffer = pixelBuffer {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                NSLog("Presentation time: \(presentationTime)")
                assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
            } else {
                print("Failed to convert processed Mat to CVPixelBuffer.")
            }
        }
    }

    
    func setupAssetWriter() -> Bool {
        let outputPath = NSTemporaryDirectory() + "processed-output-\(UUID().uuidString).mov"
        let outputURL = URL(fileURLWithPath: outputPath)

        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 1280
            ]
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            guard let assetWriterInput = assetWriterInput else { return false }

            assetWriterInput.expectsMediaDataInRealTime = true
            assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: assetWriterInput,
                sourcePixelBufferAttributes: nil
            )
            
            if assetWriter?.canAdd(assetWriterInput) == true {
                assetWriter?.add(assetWriterInput)
            } else {
                print("Could not add asset writer input.")
                return false
            }
        } catch {
            print("Failed to set up asset writer: \(error)")
            return false
        }
        return true
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        
        if let error = error {
            print("Recording failed: \(error.localizedDescription)")
        } else {
            print("Video recorded successfully at: \(outputFileURL)")
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path(), nil, nil, nil);
        }
    }
    
    

    func startRecording() {
        isRecording = true
        
        recordButton.setTitle("Stop", for: .normal)
    }
    
    func stopRecording() {
        NSLog("Tried to finish recording")
        isRecording = false
        assetWriterInput?.markAsFinished()
        assetWriter?.finishWriting {
            guard let outputURL = self.assetWriter?.outputURL else {
                print("No output URL found.")
                return
            }

            UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, self, nil, nil)

            print("Recording finished at: \(self.assetWriter?.outputURL.absoluteString ?? "Unknown URL")")
        }
        NSLog("Assetwriter finished")
        recordButton.setTitle("Record", for: .normal)

    }
}
