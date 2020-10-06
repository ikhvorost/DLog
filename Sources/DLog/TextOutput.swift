//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

// https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html
// http://jonasjacek.github.io/colors/
// https://misc.flogisoft.com/bash/tip_colors_and_formatting
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
	case backgrounRed = "\u{001b}[41m"
	case backgroundGreen = "\u{001b}[42m"
	case backgroundYellow = "\u{001b}[43m"
	case backgroundBlue = "\u{001b}[44m"
	case backgroundMagenta = "\u{001b}[45m"
	case backgroundCyan = "\u{001b}[46m"
	case backgroundWhite = "\u{001b}[47m"
}

private extension String {
	func color(_ codes: [ANSIEscapeCode]) -> String {
		return codes.map { $0.rawValue }.joined() + self + ANSIEscapeCode.reset.rawValue
	}
	
	func color(_ code: ANSIEscapeCode) -> String {
		return color([code])
	}
}

public class TextOutput : LogOutput {
	private struct Tag {
		let textColor: ANSIEscapeCode
		let colors: [ANSIEscapeCode]
	}
	
	private static let tags: [LogType : Tag] = [
		.trace : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
		.info : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
		.debug : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
		.error : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
		.fault : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite, .blink]),
		.assert : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite]),
		.interval : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textBlack]),
		// .scope
	]
	
	let color: Bool
	
	init(color: Bool = false) {
		self.color = color
	}
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm:ss.SSS"
		return dateFormatter
	}()
	
	static let dateComponentsFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		return formatter
	}()
	
	private func stringFromTime(interval: TimeInterval) -> String {
		let ms = String(format:"%.03f", interval).suffix(3)
		return Self.dateComponentsFormatter.string(from: interval)! + ".\(ms)"
	}
	
	private func textMessage(message: LogMessage) -> String {
		assert(message.time != nil)
		let time = message.time != nil ? Self.dateFormatter.string(from: message.time!) : ""
		
		var padding = ""
		if let maxlevel = message.scopes.last?.level {
			for level in 1...maxlevel {
				let scope = message.scopes.first(where: { $0.level == level })
				padding += scope != nil ? "|\t" : "\t"
			}
		}
		
		if color, let tag = Self.tags[message.type] {
			let tagText = " \(message.type.title) ".color(tag.colors)
			let location = "<\(message.fileName):\(message.line)>".color([.dim, tag.textColor])
			return "\(time.color(.dim)) \(message.category.color(.textBlue)) \(padding)\(tagText) \(location) \(message.text.color(tag.textColor))"
		}
		else {
			return "\(time) [\(message.category)] \(padding)\(message.type.icon) [\(message.type.title)] <\(message.fileName):\(message.line)> \(message.text)"
		}
	}

	private func textScope(scope: LogScope, scopes: [LogScope], start: Bool) -> String {
		let time = Self.dateFormatter.string(from: scope.time!)
		
		var padding = ""
		for level in 1..<scope.level {
			let scope = scopes.first(where: { $0.level == level })
			padding += scope != nil ? "|\t" : "\t"
		}
		padding += start ? "┌" : "└"
		
		var ms: String?
		if !start, let interval = scope.time?.timeIntervalSinceNow {
			ms = "(\(stringFromTime(interval: -interval))s)"
		}
		
		if color {
			return "\(time.color(.dim)) \(scope.category.color(.textBlue)) \(padding) [\(scope.text.color(.textMagenta))] \(ms ?? "")"
		}
		else {
			return "\(time) [\(scope.category)] \(padding) [\(scope.text)] \(ms ?? "")"
		}
	}
	
	// MARK: - LogOutput
	
	override public func log(message: LogMessage) -> String? {
		super.log(message: message)
		return textMessage(message: message)
	}
	
	override public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeEnter(scope: scope, scopes: scopes)

		return textScope(scope: scope, scopes: scopes, start: true)
	}
	
	override public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		super.scopeLeave(scope: scope, scopes: scopes)
		
		return textScope(scope: scope, scopes: scopes, start: false)
	}
	
	override public func intervalBegin(interval: LogInterval) {
		super.intervalBegin(interval: interval)
	}
	
	override public func intervalEnd(interval: LogInterval) -> String? {
		super.intervalEnd(interval: interval)
		
		let duration = stringFromTime(interval: interval.duration)
		let minDuration = stringFromTime(interval: interval.minDuration)
		let maxDuration = stringFromTime(interval: interval.maxDuration)
		let avgDuration = stringFromTime(interval: interval.avgDuration)
		let text = "[\(interval.name)] Count: \(interval.count), Total: \(duration)s, Min: \(minDuration)s, Max: \(maxDuration)s, Avg: \(avgDuration)s"
		
		let message = LogMessage(
			time: Date(),
			category: interval.category,
			type: .interval,
			fileName: interval.fileName,
			funcName: interval.funcName,
			line: interval.line,
			text: text,
			scopes: interval.scopes)
		
		return log(message: message)
	}
}
