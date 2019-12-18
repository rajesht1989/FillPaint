//
//  Image.swift
//  FillPaint
//
//  Created by Rajesh Thangaraj on 31/10/19.
//  Copyright © 2019 Rajesh Thangaraj. All rights reserved.
//

import UIKit
import CoreGraphics

extension UIImage {
    
    /*
     tolerance varies from 4 * 255 * 255
     */
    func processPixels(from point: (Int, Int), color: UIColor = .red, pattern: UIImage? = nil, tolerance: Int) -> UIImage {
        guard let coreImage = self.lineOverlayImage() else {
            return self
        }
        let bytesPerPixel    = 4
        let width            = coreImage.width
        let height           = coreImage.height
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return self
        }
        guard let cgImage = UIImage().resizeImage(targetSize: CGSize(width: size.width, height: size.height)).cgImage else {
            return self
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let buffer = context.data else {
            return self
        }
        let outputBuffer = buffer.assumingMemoryBound(to: UInt32.self)
        
        guard let inputContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return self
        }
        inputContext.draw(coreImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let inputData = inputContext.data else {
            return self
        }
        let inputBuffer = inputData.assumingMemoryBound(to: UInt32.self)
        
        let processor = ImageProcessor(inputBuffer: inputBuffer, outputBufferl: outputBuffer, dataSize: (width, height))
        processor.floodFill(from: point, with: color, tolerance: tolerance)
        
        guard let outputCGImage = context.makeImage() else {
            return self
        }
        
        if let _ = pattern {
            return filteredImage(cgImage: outputCGImage, color: color, pattern: pattern)
        } else {
            return UIImage(cgImage: outputCGImage)
        }
        
    }
    
    func lineOverlayImage() -> CGImage? {
        var cgImage: CGImage?
        if let currentFilter = CIFilter(name: "CILineOverlay") {
            currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            if let output = currentFilter.outputImage {
                let context = CIContext(options: nil)
                cgImage = context.createCGImage(output,from: output.extent)
            }
        }
        return cgImage
    }
    
    func filteredImage(cgImage: CGImage, color: UIColor, pattern: UIImage? = nil) -> UIImage {
        if let matrixFilter = CIFilter(name: "CIColorMatrix") {
            matrixFilter.setDefaults()
            matrixFilter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
            
            if let pattern = pattern {
                let rgbVector = CIVector(x: 0, y: 0, z: 0, w: 0)
                let aVector = CIVector(x: 1, y: 1, z: 1, w: 0)
                matrixFilter.setValue(rgbVector, forKey: "inputRVector")
                matrixFilter.setValue(rgbVector, forKey: "inputGVector")
                matrixFilter.setValue(rgbVector, forKey: "inputBVector")
                matrixFilter.setValue(aVector, forKey: "inputAVector")
                
                if let matrixOutput = matrixFilter.outputImage {
                    if let cgPattern = pattern.resizeImage(targetSize: size).cgImage, let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") {
                        blendFilter.setDefaults()
                        blendFilter.setValue(matrixOutput, forKey: kCIInputMaskImageKey)
                        blendFilter.setValue(CIImage(cgImage:cgPattern, options: nil), forKey: kCIInputImageKey)
                        if let blendOutput = blendFilter.outputImage, let cgImage = CIContext().createCGImage(blendOutput, from: blendOutput.extent) {
                            return UIImage(cgImage: cgImage)
                        }
                    } else if let cgImage = CIContext().createCGImage(matrixOutput, from: matrixOutput.extent) {
                        return UIImage(cgImage: cgImage)
                    }
                }
            } else {
                let pixel = Pixel(color: color)
                let rgbvalue = (CGFloat(pixel.r)/255, CGFloat(pixel.g)/255.0, CGFloat(pixel.b)/255.0)
                let aVector = CIVector(x: 1, y: 1, z: 1, w: 0)
                matrixFilter.setValue(CIVector(x: rgbvalue.0, y: 0, z: 0, w: 0), forKey: "inputRVector")
                matrixFilter.setValue(CIVector(x: 0, y: rgbvalue.1, z: 0, w: 0), forKey: "inputGVector")
                matrixFilter.setValue(CIVector(x: 0, y: 0, z: rgbvalue.2, w: 0), forKey: "inputBVector")
                matrixFilter.setValue(aVector, forKey: "inputAVector")
                matrixFilter.setValue(CIVector(x: CGFloat(pixel.r)/255, y: CGFloat(pixel.g)/255, z: CGFloat(pixel.b)/255, w: 0), forKey: "inputBiasVector")
                
                if let matrixOutput = matrixFilter.outputImage {
                    if let cgImage = CIContext().createCGImage(matrixOutput, from: matrixOutput.extent) {
                        return UIImage(cgImage: cgImage)
                    }
                }
            }
        }
        return self
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

class ImageProcessor {
    let pixelBuffer: UnsafeMutablePointer<UInt32>
    let outputBuffer: UnsafeMutablePointer<UInt32>
    let width: Int
    let height: Int
    
    init(inputBuffer: UnsafeMutablePointer<UInt32>, outputBufferl: UnsafeMutablePointer<UInt32>, dataSize: (Int,Int) ) {
        pixelBuffer = inputBuffer
        outputBuffer = outputBufferl
        width = dataSize.0
        height = dataSize.1
    }
    
    func indexFor(_ x: Int, _ y: Int) -> Int {
        return x + width*y
    }
    
    subscript(index: Int) -> Pixel {
        get {
            let pixelIndex = pixelBuffer + index
            return Pixel(memory: pixelIndex.pointee)
        }
        set(pixel) {
            self.pixelBuffer[index] = pixel.uInt32Value
            self.outputBuffer[index] = pixel.uInt32Value
        }
    }
    
    func floodFill(from point: (Int, Int), with color: UIColor, tolerance: Int) {
        let toinfo = Pixel(color: color)
        let initialIndex = indexFor(point.0, point.1)
        let fromInfo = self[initialIndex]
        let processedIndices = NSMutableIndexSet()
        let indices = NSMutableIndexSet(index: initialIndex)
        while indices.count > 0 {
            let index = indices.firstIndex
            indices.remove(index)
            if processedIndices.contains(index) {
                continue
            }
            processedIndices.add(index)
            
            if self[index].diff(fromInfo) > tolerance { continue }
            
            let pointX = index % width
            let y = index / width
            var minX = pointX
            var maxX = pointX + 1
            while minX >= 0 {
                let index = indexFor(minX, y)
                let pixelInfo = self[index]
                let diff = pixelInfo.diff(fromInfo)
                if diff > tolerance { break }
                self[index] = toinfo
                minX -= 1
            }
            while maxX < width {
                let index = indexFor(maxX, y)
                let pixelInfo = self[index]
                let diff = pixelInfo.diff(fromInfo)
                if diff > tolerance { break }
                self[index] = toinfo
                maxX += 1
            }
            for x in ((minX + 1)...(maxX - 1)) {
                if y < height - 1 {
                    let index = indexFor(x, y + 1)
                    if !processedIndices.contains(index) && self[index].diff(fromInfo) <= tolerance {
                        indices.add(index)
                    }
                }
                if y > 0 {
                    let index = indexFor(x, y - 1)
                    if !processedIndices.contains(index) && self[index].diff(fromInfo) <= tolerance {
                        indices.add(index)
                    }
                }
            }
        }
    }
}

struct Pixel {
    let r, g, b, a: UInt8
    
    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    init(memory: UInt32) {
        self.a = UInt8((memory >> 24) & 255)
        self.r = UInt8((memory >> 16) & 255)
        self.g = UInt8((memory >> 8) & 255)
        self.b = UInt8((memory >> 0) & 255)
    }
    init(color: UIColor) {
        let model = color.cgColor.colorSpace?.model
        if model == .monochrome {
            var white: CGFloat = 0
            var alpha: CGFloat = 0
            color.getWhite(&white, alpha: &alpha)
            self.r = UInt8(white * 255)
            self.g = UInt8(white * 255)
            self.b = UInt8(white * 255)
            self.a = UInt8(alpha * 255)
        } else if model == .rgb {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.r = UInt8(r * 255)
            self.g = UInt8(g * 255)
            self.b = UInt8(b * 255)
            self.a = UInt8(a * 255)
        } else {
            self.r = 0
            self.g = 0
            self.b = 0
            self.a = 0
        }
    }
    var color: UIColor {
        return UIColor(red: CGFloat(self.r) / 255, green: CGFloat(self.g) / 255, blue: CGFloat(self.b) / 255, alpha: CGFloat(self.a) / 255)
    }
    var uInt32Value: UInt32 {
        var total = (UInt32(self.a) << 24)
        total += (UInt32(self.r) << 16)
        total += (UInt32(self.g) << 8)
        total += (UInt32(self.b) << 0)
        return total
    }
    
    static func componentDiff(_ l: UInt8, _ r: UInt8) -> UInt8 {
        return max(l, r) - min(l, r)
    }
    
    func multiplyAlpha(_ alpha: CGFloat) -> Pixel {
        return Pixel(self.r, self.g, self.b, UInt8(CGFloat(self.a) * alpha))
    }
    
    func blend(_ other: Pixel) -> Pixel {
        let a1 = CGFloat(self.a) / 255.0
        let a2 = CGFloat(other.a) / 255.0
        return Pixel(
            UInt8((a1 * CGFloat(self.r)) + (a2 * (1 - a1) * CGFloat(other.r))),
            UInt8((a1 * CGFloat(self.g)) + (a2 * (1 - a1) * CGFloat(other.g))),
            UInt8((a1 * CGFloat(self.b)) + (a2 * (1 - a1) * CGFloat(other.b))),
            UInt8((255 * (a1 + a2 * (1 - a1))))
        )
    }
    
    func diff(_ other: Pixel) -> Int {
        let r = Int(Pixel.componentDiff(self.r, other.r))
        let g = Int(Pixel.componentDiff(self.g, other.g))
        let b = Int(Pixel.componentDiff(self.b, other.b))
        let a = Int(Pixel.componentDiff(self.a, other.a))
        return r*r + g*g + b*b + a*a
    }
}

extension CGImage {
    func pixelInfo(point: (Int, Int)) -> [CGFloat] {
        print(self)
        let bytesPerPixel    = 4
        let pixelData = dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelIndex: Int = Int(width * point.1 + point.0) * bytesPerPixel
        return Array(0 ... 3).map { CGFloat(data[pixelIndex + $0]) / CGFloat(255) }
    }
    
    func pointHasData(point: (Int, Int)) -> Bool {
        let pxinfo = pixelInfo(point: point)
        return pxinfo[3] > 0
    }
    
}
