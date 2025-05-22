//
//  MLCoreToPixelConverter.swift
//  FolderWatch
//
//  Created by Tomasz on 21/05/2025.
//
import Foundation

struct PixeledBox {
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
}

struct ImageSize {
    let width: Int32
    let height: Int32
    
    init(width: any BinaryInteger, height: any BinaryInteger) {
        self.width = Int32(width)
        self.height = Int32(height)
    }
}

extension PixeledBox {
    func enlarged(scale: Double, imageSize: ImageSize) -> PixeledBox {
        var width = Int32(scale * Double(self.width))
        var height = Int32(scale * Double(self.height))
        let x = max(0, self.x - ((width - self.width) / 2))
        let y = max(0, self.y - ((height - self.height) / 2))
        
        // aligh so the boubding box does not exceed the image size
        let rightBorder = x + width
        if rightBorder > imageSize.width {
            width -= rightBorder - imageSize.width
        }
        let bottomBorder = y + height
        if bottomBorder > imageSize.height {
            height -= bottomBorder - imageSize.height
        }
        return PixeledBox(x: x, y: y, width: width, height: height)
    }
}

struct MLCoreToPixelConverter {
    let imageSize: ImageSize
    
    func pixels(from boundingBox: CGRect) -> PixeledBox {
        let width = Int32(boundingBox.size.width * CGFloat(imageSize.width))
        let height = Int32(boundingBox.size.height * CGFloat(imageSize.height))
        let x = Int32(boundingBox.origin.x * CGFloat(imageSize.width))
        let y = Int32((1 - boundingBox.origin.y) * CGFloat(imageSize.height)) - height
        return PixeledBox(x: x, y: y, width: width, height: height)
    }
}
