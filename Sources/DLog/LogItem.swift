//
//  LogItem.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
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


fileprivate extension String {
  func color(_ codes: [ANSIEscapeCode]) -> String {
    return codes.map { $0.rawValue }.joined() + self + ANSIEscapeCode.reset.rawValue
  }
  
  func color(_ code: ANSIEscapeCode) -> String {
    return color([code])
  }
  
  func trimTrailingWhitespace() -> String {
    replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
  }
}

fileprivate extension Array where Element == String {
  func joinedCompact() -> String {
    compactMap { $0.isEmpty ? nil : $0 }
      .joined(separator: " ")
  }
}

fileprivate enum ANSIEscapeCode: String {
  case reset = "\u{001b}[0m"
  case clear = "\u{001b}c"
  
  case bold = "\u{001b}[1m"
  case dim = "\u{001b}[2m"
  case underline = "\u{001b}[4m"
  case blink = "\u{001b}[5m"
  case reversed = "\u{001b}[7m"
  
  // 8 colors
  case textBlack = "\u{001B}[30m"
  case textRed = "\u{001B}[31m"
  case textGreen = "\u{001B}[32m"
  case textYellow = "\u{001B}[33m"
  case textBlue = "\u{001B}[34m"
  case textMagenta = "\u{001B}[35m"
  case textCyan = "\u{001B}[36m"
  case textWhite = "\u{001B}[37m"
  
  case backgroundBlack = "\u{001b}[40m"
  case backgroundRed = "\u{001b}[41m"
  case backgroundGreen = "\u{001b}[42m"
  case backgroundYellow = "\u{001b}[43m"
  case backgroundBlue = "\u{001b}[44m"
  case backgroundMagenta = "\u{001b}[45m"
  case backgroundCyan = "\u{001b}[46m"
  case backgroundWhite = "\u{001b}[47m"
}
  
public class LogItem: @unchecked Sendable {
  fileprivate struct Tag {
    let textColor: ANSIEscapeCode
    let colors: [ANSIEscapeCode]
  }
  
  fileprivate static let tags: [LogType : Tag] = [
    .log : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
    .info : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
    .trace : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .debug : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .warning : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .error : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .fault : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite, .blink]),
    .assert : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite]),
    .intervalBegin : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
    .intervalEnd : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
    .scopeEnter : Tag(textColor: .textMagenta, colors: [.backgroundMagenta, .textBlack]),
    .scopeLeave : Tag(textColor: .textMagenta, colors: [.backgroundMagenta, .textBlack]),
  ]
  
  static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSS"
    return dateFormatter
  }()
  
  static func logPrefix(items: [(type: LogOptions, text: String)], options: LogOptions) -> String {
    items.compactMap {
      guard !$0.text.isEmpty && ($0.type == .message || options.contains($0.type)) else {
        return nil
      }
      return $0.text.trimTrailingWhitespace()
    }
    .joinedCompact()
  }
  
  public let time = Date()
  public let category: String
  public let stack: [Bool]?
  public let type: LogType
  public let location: LogLocation
  public let metadata: Metadata
  public let message: String
  public let config: LogConfig
  
  init(category: String, stack: [Bool]?, type: LogType, location: LogLocation, metadata: Metadata, message: String, config: LogConfig) {
    self.category = category
    self.stack = stack
    self.type = type
    self.location = location
    self.metadata = metadata
    self.message = message
    self.config = config
  }
  
  func padding() -> String {
    guard let stack else {
      return ""
    }
    return stack
      .map { $0 ? "| " : "  " }
      .joined()
      .appending("├")
  }
  
  func typeText() -> String {
    let tag = LogItem.tags[self.type]!
    let text = "[\(type.title)]"
    return switch config.style {
      case .plain: text
      case .colored: text.color(tag.colors)
      case .emoji: "\(type.icon) \(text)"
    }
  }
  
  func data() -> String? {
    nil
  }
  
  func messageText() -> String {
    let tag = LogItem.tags[self.type]!
    return switch config.style {
      case .plain, .emoji:
        message
      case .colored:
        message.color(tag.textColor)
    }
  }
}

extension LogItem: CustomStringConvertible {
  
  public var description: String {
    var sign = "\(config.sign)"
    var time = Self.dateFormatter.string(from: time)
    var level = String(format: "[%02d]", stack?.count ?? 0)
    var category = "[\(category)]"
    var location = "<\(location.fileName):\(location.line)>"
    var metadata = metadata.json()
    var data = data() ?? ""
    
    switch config.style {
      case .plain, .emoji:
        break
        
      case .colored:
        let tag = LogItem.tags[self.type]!
        
        sign = sign.color(.dim)
        time = time.color(.dim)
        level = level.color(.dim)
        category = category.color(.textBlue)
        location = location.color([.dim, tag.textColor])
        metadata = metadata.color(.dim)
        data = data.color(.dim)
    }
    
    let items: [(LogOptions, String)] = [
      (.sign, sign),
      (.time, time),
      (.level, level),
      (.category, category),
      (.padding, padding()),
      (.type, typeText()),
      (.location, location),
      (.metadata, metadata),
      (.data, data),
      (.message, messageText()),
    ]
    return LogItem.logPrefix(items: items, options: config.options)
  }
}
