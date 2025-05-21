//
//  BoundingBoxConverter.swift
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

extension PixeledBox {
    func enlarged(scale: Double) -> PixeledBox {
        let width = Int32(scale * Double(self.width))
        let height = Int32(scale * Double(self.height))
        let x = max(0, self.x - ((width - self.width) / 2))
        let y = max(0, self.y - ((height - self.height) / 2))
        return PixeledBox(x: x, y: y, width: width, height: height)
    }
}

struct BoundingBoxConverter {
    let imageWidth: Int
    let imageHeight: Int
    
    func pixels(from boundingBox: CGRect) -> PixeledBox {
        let width = Int32(boundingBox.size.width * CGFloat(imageWidth))
        let height = Int32(boundingBox.size.height * CGFloat(imageHeight))
        let x = Int32(boundingBox.origin.x * CGFloat(imageWidth))
        let y = Int32((1 - boundingBox.origin.y) * CGFloat(imageHeight)) - height
        return PixeledBox(x: x, y: y, width: width, height: height)
    }
}
