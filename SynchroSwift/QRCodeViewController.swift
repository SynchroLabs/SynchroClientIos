//
//  QRCodeViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 3/9/16.
//  Copyright © 2016 Robert Dickinson. All rights reserved.
//

import UIKit
import AVFoundation

extension UINavigationController {
    open override var shouldAutorotate : Bool {
        return visibleViewController!.shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return (visibleViewController?.supportedInterfaceOrientations)!
    }
}

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var messageLabel:UILabel!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var appDetail: AppDetailViewController;
    
    internal init(appDetailVC: AppDetailViewController)
    {
        self.appDetail = appDetailVC;
        super.init(nibName: "QRCodeView", bundle: nil);
        
        self.title = "Scan QR Code";
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func tapRecognizer(_ sender: UITapGestureRecognizer)
    {
        _ = self.navigationController?.popViewController(animated: true);
    }
    
    override var shouldAutorotate : Bool
    {
        if (UIDevice.current.orientation == UIDeviceOrientation.portrait ||
            UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown ||
            UIDevice.current.orientation == UIDeviceOrientation.unknown)
        {
                return true
        }
        else
        {
            return false
        }
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do
        {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Detect QR codes
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Move the message label to the top view
            view.bringSubview(toFront: messageLabel)
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView
            {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
        }
        catch
        {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
    }
    
    override func viewDidLayoutSubviews()
    {
        let bounds = self.view.layer.bounds
        videoPreviewLayer?.frame = bounds
        videoPreviewLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0
        {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
        let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
        qrCodeFrameView?.frame = barCodeObject!.bounds
        
        if metadataObj.stringValue != nil
        {
            messageLabel.text = "Endpoint - " + metadataObj.stringValue + "\n--> Tap anywhere to select <--"
            appDetail.scannedUrl = metadataObj.stringValue
        }
    }
}
