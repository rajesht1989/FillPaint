//
//  ViewController.swift
//  FillPaint
//
//  Created by Rajesh Thangaraj on 17/10/19.
//  Copyright © 2019 Rajesh Thangaraj. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate{
    
    @IBOutlet weak var imageview: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        imageview.image = UIImage(named: "Wall7.jpg")
        image = imageview.image
    }
    
    @IBAction func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let image = imageview.image else {
            return
        }
        var point = gestureRecognizer.location(in: imageview)
        let imageRect = imageview.contentClippingRect
        if imageRect.contains(point) {
            point = CGPoint(x: point.x - imageRect.origin.x, y: point.y - imageRect.origin.y)
            let imageTouchPoint: (Int, Int) = (Int(point.x * image.size.width/imageRect.size.width) , Int(point.y * image.size.height/imageRect.size.height))
            var toBeRemoved = [CALayer]()
            for layer in imageview.layer.sublayers ?? [] {
                let content = layer.contents as! CGImage
                if content.pointHasData(point: imageTouchPoint) {
                    toBeRemoved.append(layer)
                }
            }
            
            for layer in toBeRemoved {
                layer.removeFromSuperlayer()
            }
            
            var image: UIImage!
            switch Int.random(in: Range(uncheckedBounds: (0, 4))) {
            case 0:
                image = imageview.image!.processPixels(from: imageTouchPoint, color: .systemBlue, tolerance: 10)
            case 1:
                image = imageview.image!.processPixels(from: imageTouchPoint, color: .systemRed, tolerance: 10)
            default:
                image = self.imageview.image!.processPixels(from: imageTouchPoint, color: .systemBlue, pattern: UIImage(named: "Pattern.jpg"), tolerance: 100)
            }
            
            let imageLayer = CALayer()
            imageLayer.frame = imageRect
            imageLayer.contents = image.cgImage
            self.imageview.layer.addSublayer(imageLayer)
            imageLayer.opacity = 0.5
            print("Done")
        }
    }
}

extension UIImageView {
    var contentClippingRect: CGRect {
        let imageViewSize = bounds.size
        let imgSize = image?.size
        
        guard let imageSize = imgSize else {
            return CGRect.zero
        }
        
        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)
        
        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2
        return imageRect
    }
}
