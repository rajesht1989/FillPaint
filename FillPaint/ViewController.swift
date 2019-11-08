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

    var touchpointonImage: CGPoint?
    
    @IBOutlet weak var imageview: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        imageview.image = UIImage(named: "Wall1.jpg")
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
            let imageTouchPoint = CGPoint(x: point.x * image.size.width/imageRect.size.width , y: point.y * image.size.height/imageRect.size.height)
            touchpointonImage = imageTouchPoint
            let image = self.imageview.image!.convertImageToDifferentColorScale(style: "CILineOverlay").processPixels(from: (Int(imageTouchPoint.x), Int(imageTouchPoint.y)), color: .blue, tolerance: 1000)
            let imageLayer = CALayer()
            imageLayer.frame = imageRect
            imageLayer.contents = image.cgImage
            self.imageview.layer.addSublayer(imageLayer)
            imageLayer.opacity = 0.3
            
        }
    }
    
    @IBAction func toleranceValueChanged(_ slider: UISlider) {
        if let point = touchpointonImage {
            let image = self.image?.processPixels(from: (Int(point.x), Int(point.y)), color: .green, tolerance: Int(slider.value))
            imageview.image = image
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
