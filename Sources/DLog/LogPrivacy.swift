//
//  LogPrivacy.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/02/13.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation

/// Privacy options for specifying privacy level of the interpolated expressions
/// in the string interpolations passed to the logger.
public enum LogPrivacy {
    
    /// Mask options for `private` privacy level.
    public enum Mask {
        /// Hash a value in the logs.
        case hash
        
        /// Randomise a value in the logs.
        case random
        
        /// Redact a value in the logs.
        case redact
        
        /// Shuffle a value in the logs.
        case shuffle
        
        /// Replace a value with a custom string in the logs.
        /// - Parameters:
        ///   - value: A custom string.
        case custom(value: String)
        
        /// Reduce a value to a string with specified length in the logs.
        /// - Parameters:
        ///    - length: Length of an output string.
        case reduce(length: Int)
        
        /// Show parts of a value in the logs.
        /// - Parameters:
        ///    - first: Count of first visible characters.
        ///    - last: Count of last visible characters.
        case partial(first: Int, last: Int)
    }
    
    /// Sets the privacy level of an interpolated value to public.
    ///
    /// When the privacy level is public, the value will be displayed
    /// normally without any redaction in the logs.
    case `public`
    
    /// Sets the privacy level of an interpolated value to private and
    /// applies a `mask` to the interpolated value to redacted it.
    ///
    /// When the privacy level is private, the value will be redacted in the logs.
    ///
    /// - Parameters:
    ///   - mask: Mask to use with the privacy option.
    case `private`(mask: Mask)
    
    /// Sets the privacy level of an interpolated value to private.
    ///
    /// When the privacy level is private, the value will be redacted in the logs.
    ///
    public static var `private`: Self {
        .private(mask: .custom(value: "<private>"))
    }
    
    private static var isDebugger: Bool {
        getppid() != 1
    }
    
    private static let letters: [Character] = {
        let lower = (Unicode.Scalar("a").value...Unicode.Scalar("z").value)
        let upper = (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
        return [lower, upper].joined()
            .compactMap(UnicodeScalar.init)
            .map(Character.init)
    }()
    
    private static let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    private static let symbols: [Character] = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", "+",
                                       "[", "{", "]", "}", "\\", "|",
                                       ";", ":", "'", "\"",
                                       ",", "<", ".", ">", "/", "?"]
    
    private static func redact(_ text: String) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        var array = Array(text)
        for i in 0...count-1 {
            let c = array[i]
            if c.isLetter {
                array[i] = "X"
            }
            else if c.isNumber {
                array[i] = "0"
            }
        }
        return String(array)
    }
    
    private static func reduce(_ text: String, length: Int) -> String {
        let l = length > 0 ? length : 0
        guard l > 0 else {
            return "..."
        }
        
        let count = text.count
        guard count > 0, l < count  else {
            return text
        }
        
        let m = Int(l / 2)
        let s = (l % 2 == 0) ? m : m
        let e = (l % 2 == 0) ? m : m + 1
        
        let start = text.index(text.startIndex, offsetBy: s)
        let end = text.index(text.endIndex, offsetBy: -(e + 1))
        return text.replacingCharacters(in: start...end, with: "...")
    }
    
    private static func partial(_ text: String, first: Int, last: Int) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        let f = first > 0 ? first : 0
        let l = last > 0 ? last : 0
        
        guard count > f + l else {
            return text
        }
        
        let start = text.index(text.startIndex, offsetBy: f)
        let end = text.index(text.endIndex, offsetBy: -(l + 1))
        let replacement = String(repeating: "*", count: count - (f + l))
        return text.replacingCharacters(in: start...end, with: replacement)
    }
    
    private static func shuffle(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines)
            .map {
                let count = $0.count
                guard count > 1 else {
                    return $0
                }
                
                var array = Array($0)
                for i in 0...count-2 {
                    let j = Int.random(in: i+1...count-1)
                    let item = array[i]
                    array[i] = array[j]
                    array[j] = item
                }
                return String(array)
            }
            .joined(separator: " ")
    }
    
    private static func random(_ text: String) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        var array = Array(text)
        for i in 0...count-1 {
            let char = array[i]
            if char.isLetter {
                array[i] = letters.randomElement()!
            }
            else if char.isNumber {
                array[i] = digits.randomElement()!
            }
            else if char.isMathSymbol || char.isPunctuation {
                array[i] = symbols.randomElement()!
            }
        }
        return String(array)
    }
    
    
    func mask(_ text: String) -> String {
        switch self {
            
        case .public:
            return text
            
        case .private(let mask):
            // Debugger
            guard Self.isDebugger else {
                return text
            }
            
            switch mask {
                
            case .hash:
                return String(format: "%02X", text.hashValue)
                
            case .redact:
                return Self.redact(text)
                
            case .shuffle:
                return Self.shuffle(text)
                
            case .random:
                return Self.random(text)
                
            case .reduce(let length):
                return Self.reduce(text, length: length)
                
            case .partial(let first, let last):
                return Self.partial(text, first: first, last: last)
                
            case .custom(let value):
                return value
            }
        }
    }
}


