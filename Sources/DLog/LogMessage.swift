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


public class LogStringInterpolation: StringInterpolationProtocol {
    var output = ""

    public required init(literalCapacity: Int, interpolationCount: Int) {
        output.reserveCapacity(literalCapacity * 2)
    }

    public func appendLiteral(_ literal: String) {
        output.append(literal)
    }
    
    public func appendInterpolation<T: CustomStringConvertible>(_ arg: T, privacy: LogPrivacy = .public) {
        let text = privacy.mask(arg.description)
        output.append(text)
    }
    
    public func appendInterpolation(_ date: Date, format: LogDateFormatter, privacy: LogPrivacy = .public) {
        let text = format.string(from: date)
        let masked = privacy.mask(text)
        output.append(masked)
    }
    
    public func appendInterpolation(_ number: Int, format: LogNumberFormatter, privacy: LogPrivacy = .public) {
        let text = format.string(from: number)
        let masked = privacy.mask(text)
        output.append(masked)
    }
    
    public func appendInterpolation(_ byteCount: Int64, format: LogByteCountFormatter, privacy: LogPrivacy = .public) {
        let text = format.string(from: byteCount)
        let masked = privacy.mask(text)
        output.append(masked)
    }
}

public class LogMessage: NSObject, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    
    private var _description: String
    
    public override var description: String { _description }

    @objc
    public required init(stringLiteral value: String) {
        _description = value
    }

    public required init(stringInterpolation: LogStringInterpolation) {
        _description = stringInterpolation.output
    }
}
