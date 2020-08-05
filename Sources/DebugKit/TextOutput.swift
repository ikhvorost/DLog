//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class TextOutput : LogOutput {
	
	static let icons: [LogType : Character] = [
		.trace : "◻️",
		.info : "✅",
		.debug : "▶️",
		.error : "⚠️",
		.fault : "🆘"
		//.assert : "🅰️"
		//.signpost : "📍"
	]

	func writeScope(scope: LogScope, scopes: [LogScope], start: Bool) -> String {
		let time = debugDateFormatter.string(from: Date())
		
		var padding = ""
		for level in 1..<scope.level {
			let scope = scopes.first(where: { $0.level == level })
			padding += scope != nil ? "|\t" : "\t"
		}
		padding += start ? "┌" : "└"
		
		let interval = Int(scope.time.timeIntervalSinceNow * -1000)
		let ms = !start ? "(\(interval) ms)" : nil
		
		return "\(time) [\(scope.category)] \(padding) [\(scope.name)] \(ms ?? "")"
	}
	
	public func log(message: LogMessage) -> String {
		var padding = ""
		if let maxlevel = message.scopes.last?.level {
			for level in 1...maxlevel {
				let scope = message.scopes.first(where: { $0.level == level })
				padding += scope != nil ? "|\t" : "\t"
			}
		}
		
		let icon = Self.icons[message.type]!
		
		return "\(message.time) [\(message.category)] \(padding) \(icon) [\(message.type.rawValue)] <\(message.fileName):\(message.line)> \(message.text)"
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: true)
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: false)
	}
}
