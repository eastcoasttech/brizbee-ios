//
//  ScanBarCodeViewController.swift
//  BRIZBEE Mobile for iOS
//
//  Copyright © 2019 East Coast Technology Services, LLC
//
//  This file is part of BRIZBEE Mobile for iOS.
//
//  BRIZBEE Mobile for iOS is free software: you can redistribute
//  it and/or modify it under the terms of the GNU General Public
//  License as published by the Free Software Foundation, either
//  version 3 of the License, or (at your option) any later version.
//
//  BRIZBEE Mobile for iOS is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the implied
//  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with BRIZBEE Mobile for iOS.
//  If not, see <https://www.gnu.org/licenses/>.
//
//  Created by Joshua Shane Martin on 8/20/19.
//

import UIKit
import AVFoundation

class ScanBarCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var barCodeFrameView: UIView?
    var boxFrameView: UIView?
    var scannerView = UIView()
    var taskNumberDelegate: TaskNumberDelegate?
    var captured: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                print("Previously granted permission to the camera")
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        print("Just granted permission to the camera")
                    }
                }
            
            case .denied: // The user has previously denied access.
                // Alert for fatal error
                let alert = UIAlertController(title: "Oops!", message: "You have not granted permission to use your camera, so we cannot scan task numbers.", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)

            case .restricted: // The user can't grant access due to restrictions.
                // Alert for fatal error
                let alert = UIAlertController(title: "Oops!", message: "You are restricted from granting permission to use your camera, so we cannot scan task numbers.", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
        @unknown default:
            // Alert for fatal error
            let alert = UIAlertController(title: "Oops!", message: "Could not access your camera, so we cannot scan task numbers.", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
        
        captureSession = AVCaptureSession()
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
         
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
         
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession!.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            
            if (captureSession!.canAddOutput(captureMetadataOutput)) {
                captureSession!.addOutput(captureMetadataOutput)
                
                // Set delegate and use the default dispatch queue to execute the call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.code128]
            } else {
                return
            }
            
            let scannerOverlayPreviewLayer = ScannerOverlayPreviewLayer(session: captureSession!)
            scannerOverlayPreviewLayer.frame = view.bounds
            scannerOverlayPreviewLayer.maskSize = CGSize(width: 200, height: 200)
            scannerOverlayPreviewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(scannerOverlayPreviewLayer)
            captureMetadataOutput.rectOfInterest = scannerOverlayPreviewLayer.rectOfInterest
            
            // Start video capture.
            captureSession!.startRunning()
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            barCodeFrameView?.frame = CGRect.zero
//            messageLabel.text = "No bar code is detected"
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.code128 {
            // If the found metadata is equal to the Code128 code metadata then set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            barCodeFrameView?.frame = barCodeObject!.bounds

            // Take the user back to the task number view
            if metadataObj.stringValue != nil {
                if (!captured)
                {
                    let taskNumber = metadataObj.stringValue
                    captured = true
                    if let navigator = self.navigationController {
                        self.taskNumberDelegate?.taskNumber(taskNumber: taskNumber ?? "")
                        navigator.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
      layer.videoOrientation = orientation
      videoPreviewLayer?.frame = self.view.bounds
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      
      if let connection =  self.videoPreviewLayer?.connection  {
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        let previewLayerConnection : AVCaptureConnection = connection
        
        if previewLayerConnection.isVideoOrientationSupported {
          switch (orientation) {
          case .portrait:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
            break
          case .landscapeRight:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
            break
          case .landscapeLeft:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
            break
          case .portraitUpsideDown:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
            break
          default:
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
            break
          }
        }
      }
    }
}
