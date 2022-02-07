//
//  LogMessage.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/02/06.
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


public enum LogPrivacy {
    public enum Mask {
        case hash
        case random
        case redact
        case shuffle
        case partial(first: Int, last: Int)
        case custom(value: String)
    }
    
    case `public`
    case `private`(mask: Mask)
    
    public static var `private`: Self {
        .private(mask: .custom(value: "<private>"))
    }
}

public class LogStringInterpolation: StringInterpolationProtocol {
    var output = ""

    public required init(literalCapacity: Int, interpolationCount: Int) {
        output.reserveCapacity(literalCapacity * 2)
    }

    public func appendLiteral(_ literal: String) {
        output.append(literal)
    }
    
    static let letters: [Character] = {
        let lower = (Unicode.Scalar("a").value...Unicode.Scalar("z").value)
        let upper = (Unicode.Scalar("A").value...Unicode.Scalar("Z").value)
        return [lower, upper].joined()
            .compactMap(UnicodeScalar.init)
            .map(Character.init)
    }()
    
    static let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
//    static let symbols: [Character] = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", "+",
//                                       "[", "{", "]", "}", "\\", "|",
//                                       ";", ":", "'", "\"",
//                                       ",", "<", ".", ">", "/", "?"]
    
    static func redact(_ text: String) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        var array = Array(text)
        for i in 0...count-1 {
            if array[i].isLetter {
                array[i] = "X"
            }
            else if array[i].isNumber {
                array[i] = "0"
            }
        }
        return String(array)
    }
    
    static func partial(_ text: String, first: Int, last: Int) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        let f = first > 0 ? first : 0
        let l = last > 0 ? last : 0
        
        guard count > f + l else {
            return String(repeating: "*", count: count)
        }
        
        let start = text.index(text.startIndex, offsetBy: f)
        let end = text.index(text.endIndex, offsetBy: -(l + 1))
        let replacement = String(repeating: "*", count: count - (f + l))
        return text.replacingCharacters(in: start...end, with: replacement)
    }
    
    static func shuffle(_ text: String) -> String {
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
    
    static func random(_ text: String) -> String {
        let count = text.count
        guard count > 0 else {
            return text
        }
        
        var array = Array(text)
        for i in 0...count-1 {
            if array[i].isLetter {
                array[i] = letters.randomElement()!
            }
            else if array[i].isNumber {
                array[i] = digits.randomElement()!
            }
            //else {
            //    array[i] = symbols.randomElement()!
            //}
        }
        return String(array)
    }
    
    public func appendInterpolation<T>(_ arg: T, privacy: LogPrivacy = .public) where T: CustomStringConvertible {
        var text = arg.description
        
        switch privacy {
        
        case .public:
            break
        
        case .private(let mask):
            let isDebugger = getppid() != 1
            guard isDebugger == true else {
                break
            }

            switch mask {
            
            case .hash:
                text = String(format: "%02x", text.hashValue)
            
            case .redact:
                text = Self.redact(text)
                
            case .shuffle:
                text = Self.shuffle(text)
                
            case .random:
                text = Self.random(text)
            
            case .partial(let first, let last):
                text = Self.partial(text, first: first, last: last)
                
            case .custom(let value):
                text = value
            }
        }
        
        output.append(text)
    }
}

public class LogMessage: NSObject, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    
    private var _description: String
    
    public override var description: String { _description }

    public required init(stringLiteral value: String) {
        _description = value
    }

    public required init(stringInterpolation: LogStringInterpolation) {
        _description = stringInterpolation.output
    }
    
    @objc
    public static func message(_ value: String) -> Self {
        Self.init(stringLiteral: value)
    }
}
