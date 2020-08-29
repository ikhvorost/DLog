//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation
import os.log

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

// https://koenig-media.raywenderlich.com/downloads/RW-NSRegularExpression-Cheatsheet.pdf
public class ColoredOutput : TextOutput {
	
	private static let time = #"(\d{2}:\d{2}:\d{2}\.\d{3})"#
	private static let category = #"\[([^\]]+)\]"#
	private static let icon = #"(\S+\s)"#
	
	private static let logRegex: NSRegularExpression = {
		let type = #"(\[[^\]]+\])"#
		let location = #"(<\S+:\d+>)"#
		let txt = #"(.+)$"#
		let pattern = time + #"\s"# + category + #"[\s|]+"# + icon + type + #"\s"# + location + #"\s"# + txt
		return try! NSRegularExpression(pattern: pattern, options: [])
	}()
	
	private static let scopeRegex: NSRegularExpression = {
		let pattern = time + #"\s"# + category + #"[^\[]+"# + category
		return try! NSRegularExpression(pattern: pattern, options: [])
	}()
	
	private struct Tag {
		let textColor: ANSIEscapeCode
		let colors: [ANSIEscapeCode]
	}
	
	private static let tags: [String : Tag] = [
		"[" + LogType.trace.title + "]" : Tag(textColor: .textWhite, colors: [.backgroundWhite, .textBlack]),
		"[" + LogType.info.title + "]" : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
		"[" + LogType.interval.title + "]" : Tag(textColor: .textGreen, colors: [.backgroundGreen, .textWhite]),
		"[" + LogType.assert.title + "]" : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite]),
		"[" + LogType.debug.title + "]" : Tag(textColor: .textCyan, colors: [.backgroundCyan, .textBlack]),
		"[" + LogType.error.title + "]" : Tag(textColor: .textYellow, colors: [.backgroundYellow, .textBlack]),
		"[" + LogType.fault.title + "]" : Tag(textColor: .textRed, colors: [.backgrounRed, .textWhite, .blink]),
	]
	
	private func insert(text: inout String, range: NSRange, codes: [ANSIEscapeCode]) {
		guard let r = Range(range, in: text) else { return }
		
		text.insert(contentsOf: ANSIEscapeCode.reset.rawValue, at: r.upperBound)
		let items = codes.map { $0.rawValue }.joined()
		text.insert(contentsOf: items, at: r.lowerBound)
	}
	
	private func paint(_ text: String) -> String {
		var t = text
		
		let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
		
		// Log
		if let match = Self.logRegex.firstMatch(in: text, options: [], range: nsrange) {
			assert(match.numberOfRanges == 7)
			
			let typeRange = match.range(at: 4)
			let type = text[Range(typeRange, in: text)!]
			let tag = Self.tags[String(type)]!
			
			let textRange = match.range(at: 6)
			insert(text: &t, range: textRange, codes: [tag.textColor])
			
			let locationRange = match.range(at: 5)
			insert(text: &t, range: locationRange, codes: [.dim, tag.textColor])
			
			//let typeRange = match.range(at: 4)
			insert(text: &t, range: typeRange, codes: tag.colors)
			
			let iconRange = match.range(at: 3)
			t = t.replacingCharacters(in: Range(iconRange, in: t)!, with: "")
			
			let categoryRange = match.range(at: 2)
			insert(text: &t, range: categoryRange, codes: [.textBlue])
			
			let timeRange = match.range(at: 1)
			insert(text: &t, range: timeRange, codes: [.dim])
		}
		// Scope
		else if let match = Self.scopeRegex.firstMatch(in: text, options: [], range: nsrange) {
			assert(match.numberOfRanges == 4)
			
			let scopeRange = match.range(at: 3)
			insert(text: &t, range: scopeRange, codes: [.textMagenta])
			
			let categoryRange = match.range(at: 2)
			insert(text: &t, range: categoryRange, codes: [.textBlue])
			
			let timeRange = match.range(at: 1)
			insert(text: &t, range: timeRange, codes: [.dim])
		}

		return t
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String {
		paint(super.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		paint(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		paint(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalBegin(interval: LogInterval) {
	}
	
	override func intervalEnd(interval: LogInterval) -> String {
		paint(super.intervalEnd(interval: interval))
	}
}
