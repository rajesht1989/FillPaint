//
//  ViewController.swift
//  FillPaint
//
//  Created by Rajesh Thangaraj on 17/10/19.
//  Copyright © 2019 Rajesh Thangaraj. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate{

    var touchpoint:CGPoint?
    
    @IBOutlet weak var imageview: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = imageview.image
    }

    @IBAction func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        let point = gestureRecognizer.location(in: imageview)
        let imageTouchPoint = CGPoint(x: point.x / (imageview.bounds.size.width/imageview.image!.size.width) , y: point.y / (imageview.bounds.size.height/imageview.image!.size.height))
        touchpoint = imageTouchPoint
        let image = self.imageview.image?.processPixels(from: (Int(imageTouchPoint.x), Int(imageTouchPoint.y)), color: .green, tolerance: 1000)
        imageview.image = image
    }
    
    @IBAction func toleranceValueChanged(_ slider: UISlider) {
        if let point = touchpoint {
            let image = self.imageview.image?.processPixels(from: (Int(point.x), Int(point.y)), color: .green, tolerance: Int(slider.value))
            imageview.image = image
        }
    }
}
