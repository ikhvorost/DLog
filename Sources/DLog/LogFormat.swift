//
//  LogFormat.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/02/14.
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


public enum LogDateFormatter {
    case dateStyle(date: DateFormatter.Style = .none, time: DateFormatter.Style = .none, locale: Locale = Locale(identifier: "en_US"))
    case dateCustom(format: String)
    
    private static let formatter = DateFormatter()
    
    func string(from date: Date) -> String {
        synchronized(Self.formatter) {
            switch self {

            case let .dateStyle(dateStyle, timeStyle, locale):
                Self.formatter.locale = locale
                Self.formatter.dateStyle = dateStyle
                Self.formatter.timeStyle = timeStyle
                return Self.formatter.string(from: date)

            case let .dateCustom(format):
                Self.formatter.dateFormat = format
                return Self.formatter.string(from: date)
            }
        }
    }
}


public enum LogNumberFormatter {
    case number(style: NumberFormatter.Style, locale: Locale = Locale(identifier: "en_US"))
    
    private static let formatter = NumberFormatter()
    
    func string(from number: Int) -> String {
        synchronized(Self.formatter) {
            switch self {
                
            case let .number(style, locale):
                Self.formatter.locale = locale
                Self.formatter.numberStyle = style
                return Self.formatter.string(from: NSNumber(value: number)) ?? ""
            }
        }
    }
}

public enum LogByteCountFormatter {
    case byteCount(countStyle: ByteCountFormatter.CountStyle = .file, allowedUnits: ByteCountFormatter.Units = .useMB)
    
    private static let formatter = ByteCountFormatter()
    
    func string(from byteCount: Int64) -> String {
        synchronized(Self.formatter) {
            switch self {
            case let .byteCount(countStyle, allowedUnits):
                Self.formatter.countStyle = countStyle
                Self.formatter.allowedUnits = allowedUnits
                return Self.formatter.string(fromByteCount: byteCount)
            }
        }
    }
}
