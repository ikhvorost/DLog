//
//  LogItem+Text.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/03.
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

fileprivate extension Array where Element == String {
  func joinedCompact() -> String {
    compactMap { $0.isEmpty ? nil : $0 }
      .joined(separator: " ")
  }
}

enum ANSIEscapeCode: String {
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

extension String {
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

extension LogType {
  static let icons: [LogType : String] = [
    .log : "💬",
    .trace : "#️⃣",
    .debug : "▶️",
    .info : "✅",
    .warning: "⚠️",
    .error : "⚠️",
    .assert : "🅰️",
    .fault : "🆘",
    .interval : "🕒",
    .scopeEnter: "⬇️",
    .scopeLeave: "⬆️",
  ]
  
  var icon: String {
    Self.icons[self]!
  }
  
  static let titles: [LogType : String] = [
    .log : "LOG",
    .trace : "TRACE",
    .debug : "DEBUG",
    .info : "INFO",
    .warning : "WARNING",
    .error : "ERROR",
    .assert : "ASSERT",
    .fault : "FAULT",
    .interval : "INTERVAL",
    .scopeEnter : "SCOPE",
    .scopeLeave : "SCOPE",
  ]
  
  var title: String {
    Self.titles[self]!
  }
}

extension LogItem {
  
  struct Tag {
    let textColor: ANSIEscapeCode
    let colors: [ANSIEscapeCode]
  }
  
  static let tags: [LogType : Tag] = [
    .log : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
    .info : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
    .trace : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .debug : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .warning : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .error : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .fault : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite, .blink]),
    .assert : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite]),
    .interval : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
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
      guard options.contains($0.type) || $0.type == .message else {
        return nil
      }
      return $0.text.trimTrailingWhitespace()
    }
    .joinedCompact()
  }
  
  func text() -> String {
    var sign = "\(config.sign)"
    var time = Self.dateFormatter.string(from: self.time)
    var level = String(format: "[%02d]", self.stack?.count ?? "")
    var category = "[\(self.category)]"
    let padding = self.stack?
        .map { $0 ? "| " : "  " }
        .joined()
        .appending("├") ?? ""
    var type = "[\(self.type.title)]"
    var location = "<\(self.location.fileName):\(self.location.line)>"
    var metadata = self.metadata
        .filter { $0.isEmpty == false }
        .map {
          let pretty = self.type == .trace && self.config.traceConfig.style == .pretty
          return $0.json(pretty: pretty)
        }
        .joined(separator: " ")
    var message = message
    
    switch config.style {
      case .plain:
        break
        
      case .colored:
        assert(Self.tags[self.type] != nil)
        let tag = Self.tags[self.type]!
        
        sign = sign.color(.dim)
        time = time.color(.dim)
        level = level.color(.dim)
        category = category.color(.textBlue)
        type = " \(self.type.title) ".color(tag.colors)
        location = location.color([.dim, tag.textColor])
        metadata = metadata.color(.dim)
        message = message.color(tag.textColor)
        
      case .emoji:
        type = "\(self.type.icon) [\(self.type.title)]"
    }
    
    let items: [(LogOptions, String)] = [
      (.sign, sign),
      (.time, time),
      (.level, level),
      (.category, category),
      (.padding, padding),
      (.type, type),
      (.location, location),
      (.metadata, metadata)
    ]
    let prefix = Self.logPrefix(items: items, options: config.options)
    return [prefix, message].joinedCompact()
  }
}
