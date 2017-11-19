//
//  Slide.swift
//  DeckRocket
//
//  Created by JP Simard on 4/8/15.
//  Copyright (c) 2015 JP Simard. All rights reserved.
//

import CoreGraphics
import Foundation

#if os(OSX)
    import AppKit
    typealias Image = NSImage

    extension NSImage {
        func imageByScalingWithFactor(factor: CGFloat) -> NSImage {
            let targetSize = CGSize(width: size.width * factor, height: size.height * factor)
            let targetRect = NSRect(origin: NSZeroPoint, size: targetSize)
            let newImage = NSImage(size: targetSize)
            newImage.lockFocus()
            draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1)
            newImage.unlockFocus()
            return newImage
        }
    }
#else
    import UIKit
    typealias Image = UIImage

    extension UIImage {
        func resizeImage(_ newSize: CGSize) -> (UIImage) {
            let newRect = CGRect(origin: CGPoint.zero, size: newSize).integral
            let imageRef = self.cgImage!

            UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
            let context = UIGraphicsGetCurrentContext()!

            // Set the quality level to use when rescaling
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)

            context.concatenate(flipVertical)
            // Draw into the context; this scales the image
            context.draw(imageRef, in: newRect)

            let newImageRef = context.makeImage()!
            let newImage = UIImage(cgImage: newImageRef)

            // Get the resized image from the context and a UIImage
            UIGraphicsEndImageContext()
            return newImage
        }
    }
#endif

struct Slide {
    let image: Image
    let notes: String?

    init(image: Image, notes: String?) {
        self.image = image
        self.notes = notes
    }

    init?(dictionary: NSDictionary) {
        guard let image = (dictionary["image"] as? NSData).flatMap({ Image(data: $0 as Data) }) else {
            return nil
        }
        self.init(image: image, notes: dictionary["notes"] as? String)
    }

    static func slidesfromData(_ data: Data) -> [Slide?]? {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [NSDictionary]
        return dict.flatMap { data in
            data.map {
                guard let imageData = $0["image"] as? NSData, let image = Image(data: imageData as Data) else {
                    return nil
                }
                return Slide(image: image, notes: $0["notes"] as? String)
            }
        }
    }

    #if os(OSX)
    init?(pdfData: NSData, notes: String?) {
        guard let pdfImageRep = NSPDFImageRep(data: pdfData as Data) else { return nil }
        let image = NSImage()
        image.addRepresentation(pdfImageRep)
        self.init(image: image.imageByScalingWithFactor(factor: 0.5), notes: notes)
    }

    var dictionaryRepresentation: NSDictionary? {
        return image.tiffRepresentation.flatMap {
            return NSBitmapImageRep(data: $0)?.representation(using: .jpeg,
                                                                       properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 0.5])
        }.flatMap {
            return ["image": $0, "notes": notes ?? ""]
        }
    }
    #else
    var dictionaryRepresentation: NSDictionary? {
        let newSize = CGSize(width: 16 * 2, height: 9 * 2)
        return UIImageJPEGRepresentation(image.resizeImage(newSize), 0.5).flatMap {
            return ["image": $0, "notes": ""]
        }
    }
    #endif
}
