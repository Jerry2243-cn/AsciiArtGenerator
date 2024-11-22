//
//  AsciiGenerator.swift
//  StormCrew
//
//  Created by Jerry Zhu on 2024/11/22.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

class AsciiArtGenerator {
    private let asciiChars = ["@", "%", "#", "*", "+", "=", "-", ":", ".", " "]
    private let minWidth: CGFloat = 10.0
    private let maxWidth: CGFloat = 200.0
    
    struct Configuration {
        var isColored: Bool = true
        var useMonospacedFont: Bool = true
        var fontSize: CGFloat = 6.0
        var fontName: String = "Menlo"
        var characterAspectRatio: CGFloat = 1
        var lineHeight: CGFloat = 6.0
        var letterSpacing: CGFloat = 2.5
    }
    
    func generate(image: UIImage, precision: CGFloat, configuration: Configuration = Configuration()) -> NSAttributedString? {
        return generateAsciiArt(image: image, precision: precision, configuration: configuration)
    }
    
    func generateAsync(image: UIImage, precision: CGFloat, configuration: Configuration = Configuration(), completion: @escaping (NSAttributedString?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.generateAsciiArt(image: image, precision: precision, configuration: configuration)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func generateHTML(image: UIImage, precision: CGFloat, configuration: Configuration = Configuration()) -> String? {
        let clampedPrecision = max(0.0, min(1.0, precision))
        let aspectRatio = image.size.width / image.size.height
        let fontSize = configuration.fontSize
        let fontName = configuration.fontName
        let charAspectRatio: CGFloat = configuration.characterAspectRatio
        let newWidth = max(minWidth, min(maxWidth, image.size.width * clampedPrecision))
        let newHeight = CGFloat(newWidth) / (aspectRatio * charAspectRatio)
        
        guard let resizedImage = resizeImage(image: image, newSize: CGSize(width: CGFloat(newWidth), height: newHeight)),
              let pixelData = getPixelDataWithColor(image: resizedImage) else {
            return nil
        }
        
        let width = Int(resizedImage.size.width)
        let height = Int(resizedImage.size.height)
        
        var htmlString = """
        <div style="font-family: \(fontName); font-size: \(fontSize)px; line-height: \(configuration.lineHeight)px; letter-spacing: \(configuration.letterSpacing)px; white-space: pre; background-color: black; color: white;">
        """
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let pixel = pixelData[index]
                let intensity = (0.299 * Double(pixel.red) + 0.587 * Double(pixel.green) + 0.114 * Double(pixel.blue))
                let charIndex = Int((intensity / 255.0) * Double(asciiChars.count - 1))
                let asciiChar = asciiChars[charIndex]
                
                if configuration.isColored {
                    let colorHex = String(format: "#%02X%02X%02X", pixel.red, pixel.green, pixel.blue)
                    htmlString += "<span style=\"color: \(colorHex);\">\(asciiChar)</span>"
                } else {
                    htmlString += asciiChar
                }
            }
            htmlString += "\n"
        }
        
        htmlString += "</div>"
        return htmlString
    }
    
    private func generateAsciiArt(image: UIImage, precision: CGFloat, configuration: Configuration) -> NSAttributedString? {
        let clampedPrecision = max(0.0, min(1.0, precision))
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let aspectRatio = originalWidth / originalHeight
        let charAspectRatio = configuration.characterAspectRatio
        let newWidth = max(minWidth, min(maxWidth, originalWidth * clampedPrecision))
        let newHeight = CGFloat(newWidth) / (aspectRatio * charAspectRatio)
        
        guard let resizedImage = resizeImage(image: image, newSize: CGSize(width: CGFloat(newWidth), height: newHeight)),
              let pixelData = getPixelDataWithColor(image: resizedImage) else {
            return nil
        }
        
        let width = Int(resizedImage.size.width)
        let height = Int(resizedImage.size.height)
        
        let attributedString = NSMutableAttributedString()
        let font: UIFont
        if configuration.useMonospacedFont {
            font = UIFont(name: configuration.fontName, size: configuration.fontSize) ?? UIFont.monospacedSystemFont(ofSize: configuration.fontSize, weight: .regular)
        } else {
            font = UIFont.systemFont(ofSize: configuration.fontSize)
        }
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let pixel = pixelData[index]
                let intensity = (0.299 * Double(pixel.red) + 0.587 * Double(pixel.green) + 0.114 * Double(pixel.blue))
                let charIndex = Int((intensity / 255.0) * Double(asciiChars.count - 1))
                let asciiChar = asciiChars[charIndex]
                
                var attributes: [NSAttributedString.Key: Any] = [.font: font]
                
                if configuration.isColored {
                    attributes[.foregroundColor] = UIColor(red: CGFloat(pixel.red) / 255.0, green: CGFloat(pixel.green) / 255.0, blue: CGFloat(pixel.blue) / 255.0, alpha: 1.0)
                } else {
                    let grayValue = CGFloat(intensity / 255.0)
                    attributes[.foregroundColor] = UIColor(white: grayValue, alpha: 1.0)
                }
                
                let attributedChar = NSAttributedString(string: asciiChar, attributes: attributes)
                attributedString.append(attributedChar)
            }
            attributedString.append(NSAttributedString(string: "\n"))
        }
        
        return attributedString
    }
    
    private func resizeImage(image: UIImage, newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func getPixelDataWithColor(image: UIImage) -> [PixelData]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var pixelValues = [PixelData]()
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let red = pointer[offset]
                let green = pointer[offset + 1]
                let blue = pointer[offset + 2]
                pixelValues.append(PixelData(red: red, green: green, blue: blue))
            }
        }
        
        return pixelValues
    }
    
    private struct PixelData {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
    }
}
