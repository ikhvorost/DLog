//
//  Text.swift
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

private enum ANSIEscapeCode: String {
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

private extension LogType {
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
  ]
  
  var title: String {
    Self.titles[self]!
  }
}

/// A source output that generates text representation of log messages.
///
/// It doesn’t deliver text to any target outputs (stdout, file etc.) and usually other outputs use it.
///
public class Text : LogOutput {
  
  private struct Tag {
    let textColor: ANSIEscapeCode
    let colors: [ANSIEscapeCode]
  }
  
  private static let tags: [LogType : Tag] = [
    .log : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
    .info : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
    .trace : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .debug : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
    .warning : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .error : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
    .fault : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite, .blink]),
    .assert : Tag(textColor: .textRed, colors: [.backgroundRed, .textWhite]),
    .interval : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
  ]
  
  /// Style of text to output.
  public enum Style {
    /// Universal plain text.
    case plain
    
    /// Text with type icons for info, debug etc. (useful for XCode console).
    case emoji
    
    /// Colored text with ANSI escape codes (useful for Terminal and files).
    case colored
  }
  
  private let style: Style
  
  /// Creates `Text` source output object.
  ///
  /// 	let logger = DLog(Text(style: .emoji))
  /// 	logger.info("It's emoji text")
  ///
  /// - Parameters:
  ///		- style: Style of text to output (defaults to `.plain`).
  ///
  public init(style: Style = .plain) {
    self.style = style
    
    super.init(source: nil)
  }
  
  private static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSS"
    return dateFormatter
  }()
  
  private func logPrefix(items: [(LogOptions, () -> String)], options: LogOptions) -> String {
    items.compactMap {
      guard options.contains($0.0) else {
        return nil
      }
      let text = $0.1()
      return text.trimTrailingWhitespace()
    }
    .joinedCompact()
  }
  
  private func textMessage(item: LogItem) -> String {
    var sign = { "\(item.config.sign)" }
    var time = { Self.dateFormatter.string(from: item.time) }
    var level = { String(format: "[%02d]", item.scope?.level ?? 0) }
    var category = { "[\(item.category)]" }
    let padding = {
      guard let scope = item.scope, scope.level > 0 else { return "" }
      return (1...scope.level)
        .map {
          ScopeStack.shared.exists(level: $0)
          ? ($0 == scope.level) ? "├ " : "│ "
          : "  "
        }
        .joined()
    }
    var type = { "[\(item.type.title)]" }
    var location = { "<\(item.location.fileName):\(item.location.line)>" }
    var metadata = {
      item.metadata
        .filter { $0.isEmpty == false }
        .map {
          let pretty = item.type == .trace && item.config.traceConfig.style == .pretty
          return $0.json(pretty: pretty)
        }
        .joined(separator: " ")
    }
    
    var message = item.message
    
    switch style {
      case .plain:
        break
        
      case .colored:
        assert(Self.tags[item.type] != nil)
        let tag = Self.tags[item.type]!
        
        let s = sign
        sign = { s().color(.dim) }
        
        let t = time
        time = { t().color(.dim) }
        
        let l = level
        level = { l().color(.dim) }
        
        category = { item.category.color(.textBlue) }
        type = { " \(item.type.title) ".color(tag.colors) }
        
        let loc = location
        location = { loc().color([.dim, tag.textColor]) }
        
        let m = metadata
        metadata = { m().color(.dim) }
        
        message = message.color(tag.textColor)
        
      case .emoji:
        type = { "\(item.type.icon) [\(item.type.title)]" }
    }
    
    let items: [(LogOptions, () -> String)] = [
      (.sign, sign),
      (.time, time),
      (.level, level),
      (.category, category),
      (.padding, padding),
      (.type, type),
      (.location, location),
      (.metadata, metadata)
    ]
    let prefix = logPrefix(items: items, options: item.config.options)
    return [prefix, message].joinedCompact()
  }
  
  private func textScope(scope: LogScope) -> String {
    let start = scope.duration == 0
    
    var sign = { "\(scope.config.sign)" }
    var time = start
    ? Self.dateFormatter.string(from: scope.time)
    : Self.dateFormatter.string(from: scope.time.addingTimeInterval(scope.duration))
    let ms = !start ? "(\(stringFromTimeInterval(scope.duration)))" : nil
    var category = { "[\(scope.category)]" }
    var level = { String(format: "[%02d]", scope.level) }
    let padding: () -> String = {
      let text = (1..<scope.level)
        .map { ScopeStack.shared.exists(level: $0) ? "| " : "  " }
        .joined()
      return "\(text)\(start ? "┌" : "└")"
    }
    var text = "[\(scope.name)] \(ms ?? "")"
    
    switch style {
      case .emoji, .plain:
        break
        
      case .colored:
        sign = { "\(scope.config.sign)".color(.dim) }
        time = time.color(.dim)
        level = { String(format: "[%02d]", scope.level).color(.dim) }
        category = { scope.category.color(.textBlue) }
        text = "[\(scope.name.color(.textMagenta))] \((ms ?? "").color(.dim))"
    }
    
    let items: [(LogOptions, () -> String)] = [
      (.sign, sign),
      (.time, { time }),
      (.level, level),
      (.category, category),
      (.padding, padding),
    ]
    let prefix = logPrefix(items: items, options: scope.config.options)
    return prefix.isEmpty ? text : "\(prefix) \(text)"
  }
  
  // MARK: - LogOutput
  
  override func log(item: LogItem) -> String? {
    super.log(item: item)
    return textMessage(item: item)
  }
  
  override func scopeEnter(scope: LogScope) -> String? {
    super.scopeEnter(scope: scope)
    
    return textScope(scope: scope)
  }
  
  override func scopeLeave(scope: LogScope) -> String? {
    super.scopeLeave(scope: scope)
    
    return textScope(scope: scope)
  }
  
  override func intervalBegin(interval: LogInterval) {
    super.intervalBegin(interval: interval)
  }
  
  override func intervalEnd(interval: LogInterval) -> String? {
    super.intervalEnd(interval: interval)
    
    return textMessage(item: interval)
  }
}
