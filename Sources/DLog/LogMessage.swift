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

/// Represents a string interpolation passed to the logger.
///
/// - Warning: Do not call this function directly. It will be called automatically when interpolating
/// a value of generic type in the string interpolations passed to the logger.
///
public struct LogStringInterpolation: StringInterpolationProtocol {
  var value = ""
  
  /// Creates an empty instance ready to be filled with string literal content.
  public init(literalCapacity: Int, interpolationCount: Int) {
    value.reserveCapacity(literalCapacity)
  }
  
  /// Appends a literal segment to the interpolation.
  public mutating func appendLiteral(_ literal: String) {
    value.append(literal)
  }
  
  /// Defines interpolation for expressions of Any type.
  public mutating func appendInterpolation(_ value: @autoclosure () -> Any, privacy: LogPrivacy = .public) {
    let text = String(describing: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
  
  /// Defines interpolation for expressions of date type.
  public mutating func appendInterpolation(_ value: @autoclosure () -> Date, format: LogDateFormatting, privacy: LogPrivacy = .public) {
    let text = format.string(from: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
  
  /// Defines interpolation for expressions of integer values.
  public mutating func appendInterpolation<T: BinaryInteger>(_ value: @autoclosure () -> T, format: LogIntFormatting, privacy: LogPrivacy = .public) {
    let text = format.string(from: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
  
  /// Defines interpolation for expressions of floating-point values.
  public mutating func appendInterpolation<T: BinaryFloatingPoint>(_ value: @autoclosure () -> T, format: LogFloatFormatting, privacy: LogPrivacy = .public) {
    let text = format.string(from: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
  
  /// Defines interpolation for expressions of boolean values.
  public mutating func appendInterpolation(_ value: @autoclosure () -> Bool, format: LogBoolFormatting, privacy: LogPrivacy = .public) {
    let text = format.string(from: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
  
  /// Defines interpolation for expressions of Data.
  public mutating func appendInterpolation(_ value: @autoclosure () -> Data, format: LogDataFormatting, privacy: LogPrivacy = .public) {
    let text = format.string(from: value())
    let masked = privacy.mask(text)
    self.value.append(masked)
  }
}

/// An object that represents a log message.
///
/// Represents a message passed to the logger. This type should be created from a string
/// interpolation or a string literal.
///
/// - Warning: Do not explicitly refer to this type. It will be implicitly created by the compiler
/// when you pass a string interpolation to the logger.
///
public struct LogMessage: ExpressibleByStringInterpolation, Sendable {
  private let value: String
  
  init(items: [Any]) {
    value = items
      .map { "\($0)" }
      .joined(separator: " ")
  }
  
  /// Creates an instance initialized to the given string value.
  public init(stringLiteral value: String) {
    self.value = value
  }

  /// Creates an instance of a log message from a string interpolation.
  public init(stringInterpolation: LogStringInterpolation) {
    value = stringInterpolation.value
  }
}

extension LogMessage: CustomStringConvertible {
  public var description: String { value }
}
