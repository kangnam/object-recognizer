//
//  ViewController.swift
//  Object Recognizer
//
//  Created by Kang Nam on 6/21/18.
//  Copyright © 2018 Kang Nam. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupObjectLabel()
        setupCaptureSession()
        
        
    }
    
    func setupCaptureSession() {
        let captureSession: AVCaptureSession = AVCaptureSession()
        guard let captureDevice: AVCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        view.layer.addSublayer(previewLayer)
        view.layer.sublayers?.insert(previewLayer, at: 0)
        previewLayer.frame = view.frame
        
        let dataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model: VNCoreMLModel = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request: VNCoreMLRequest = VNCoreMLRequest(model: model) { (request, err) in
            if let err = err {
                print("Failure:", err)
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else { return }
            guard let firstObservation: VNClassificationObservation = results.first else { return }
            print(firstObservation.identifier, firstObservation.confidence)
            
            self.setObjectLabel(text: self.getFirst(object: firstObservation.identifier), probability: firstObservation.confidence)
            
            
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    
    func getFirst(object: String) -> String {
        var name: String = ""
        for char in object {
            if char == "," {
                return name
            } else {
                name.append(char)
            }
        }
        return name
    }
    
    func setupObjectLabel() {
        view.addSubview(objectLabel)
        objectLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        objectLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        objectLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        objectLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        objectLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
    }
    
    let objectLabel: UILabel = {
        let label: UILabel = UILabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.8)
        label.text = "undefined"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.layer.cornerRadius = 25
        label.clipsToBounds = true
        label.textColor = .white
        return label
    }()
    
    func setObjectLabel(text: String, probability: Float) {
        DispatchQueue.main.async {
            self.objectLabel.text = "\(text) w/ prob \(probability*100)%"
        }
        
    }

    
}

