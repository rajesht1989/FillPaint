//
//  ViewController.swift
//  FillPaint
//
//  Created by Rajesh Thangaraj on 17/10/19.
//  Copyright © 2019 Rajesh Thangaraj. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate{

    var touchpointonImage: CGPoint?
    
    @IBOutlet weak var imageview: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageview.image = UIImage(named: "Wall2.jpg")
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
            let image = self.imageview.image?.processPixels(from: (Int(imageTouchPoint.x), Int(imageTouchPoint.y)), color: .green, tolerance: 100)
            imageview.image = image
        }
    }
    
    @IBAction func toleranceValueChanged(_ slider: UISlider) {
        if let point = touchpointonImage {
            let image = self.image?.processPixels(from: (Int(point.x), Int(point.y)), color: .green, tolerance: Int(slider.value))
            imageview.image = image
        }
    }
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
