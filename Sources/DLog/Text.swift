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
		.scope : "",
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
		.scope: ""
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
	/// 	let log = DLog(Text(style: .emoji))
	/// 	log.info("It's emoji text")
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
	
	private static let dateComponentsFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		return formatter
	}()
	
	static func stringFromTime(interval: TimeInterval) -> String {
		let ms = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
		return dateComponentsFormatter.string(from: interval)! + ".\(ms)"
	}
	
	private func logPrefix(items: [(LogOptions, () -> String)], options: LogOptions) -> String {
		items
			.compactMap {
				guard options.contains($0.0) else { return nil }
				let text = $0.1()
				return !text.isEmpty ? text.trimTrailingWhitespace() : nil
			}
			.joined(separator: " ")
	}
	
	private func textMessage(item: LogItem, scopes: [LogScope]) -> String {
		assert(item.type != .scope)
		
		var sign = { "\(item.config.sign)" }
		var time = { Self.dateFormatter.string(from: item.time) }
		var level = { String(format: "[%02d]", item.scope?.level ?? 0) }
		var category = { "[\(item.category)]" }
		let padding: () -> String = {
			var text = ""
			if let scope = item.scope, scope.entered {
				for level in 1...scope.level {
					let scope = scopes.first(where: { $0.level == level })
					text += scope != nil ? "| " : "  "
				}
			}
			return text
		}
		var type = { "[\(item.type.title)]" }
		var location = { "<\(item.fileName):\(item.line)>" }
		var text = item.text()
		
		switch style {
			case .plain:
				break
				
			case .colored:
				assert(Self.tags[item.type] != nil)
				let tag = Self.tags[item.type]!
				
				sign = { "\(item.config.sign)".color(.dim) }
				time = { Self.dateFormatter.string(from: item.time).color(.dim) }
				level = { String(format: "[%02d]", item.scope?.level ?? 0).color(.dim) }
				category = { "[\(item.category)]" }
				type = { "[\(item.type.title)]" }
				location = { "<\(item.fileName):\(item.line)>".color([.dim, tag.textColor]) }
				text = text.color(tag.textColor)
				
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
			(.location, location)
		]
		let prefix = logPrefix(items: items, options: item.config.options)
		return prefix.isEmpty ? text : "\(prefix) \(text)"
	}

	private func textScope(scope: LogScope, scopes: [LogScope]) -> String {
		let start = scope.duration == 0
		
		var sign = { "\(scope.config.sign)" }
		var time = start ? Self.dateFormatter.string(from: scope.time) : Self.dateFormatter.string(from: scope.time.addingTimeInterval(scope.duration))
		let ms = !start ? "(\(Self.stringFromTime(interval: scope.duration)))" : nil
		var category = { "[\(scope.category)]" }
		var level = { String(format: "[%02d]", scope.level) }
		let padding: () -> String = {
			var text = ""
			for level in 1..<scope.level {
				let scope = scopes.first(where: { $0.level == level })
				text += scope != nil ? "| " : "  "
			}
			text += start ? "┌" : "└"
			return text
		}
		var text = "[\(scope.text())] \(ms ?? "")"
		
		switch style {
			case .emoji, .plain:
				break

			case .colored:
				sign = { "\(scope.config.sign)".color(.dim) }
				time = time.color(.dim)
				level = { String(format: "[%02d]", scope.level).color(.dim) }
				category = { scope.category.color(.textBlue) }
				text = "[\(scope.text().color(.textMagenta))]"
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
	
	override func log(item: LogItem, scopes: [LogScope]) -> String? {
		super.log(item: item, scopes: scopes)
		return textMessage(item: item, scopes: scopes)
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeEnter(scope: scope, scopes: scopes)

		return textScope(scope: scope, scopes: scopes)
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeLeave(scope: scope, scopes: scopes)
		
		return textScope(scope: scope, scopes: scopes)
	}
	
	override func intervalBegin(interval: LogInterval) {
		super.intervalBegin(interval: interval)
	}
	
	override func intervalEnd(interval: LogInterval, scopes: [LogScope]) -> String? {
		super.intervalEnd(interval: interval, scopes: scopes)
		
		return textMessage(item: interval, scopes: scopes)
	}
}
