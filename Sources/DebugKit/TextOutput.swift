//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class TextOutput : LogOutput {
	
	static let dateComponentsFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		return formatter
	}()
	
	func stringFromTime(interval: TimeInterval) -> String {
		let ms = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
		return Self.dateComponentsFormatter.string(from: interval)! + ".\(ms)"
	}

	func writeScope(scope: LogScope, scopes: [LogScope], start: Bool) -> String {
		let time = debugDateFormatter.string(from: Date())
		
		var padding = ""
		for level in 1..<scope.level {
			let scope = scopes.first(where: { $0.level == level })
			padding += scope != nil ? "|\t" : "\t"
		}
		padding += start ? "┌" : "└"
		
		let interval = -scope.time.timeIntervalSinceNow
		let ms = !start ? "(\(stringFromTime(interval: interval)))" : nil
		
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
		
		return "\(message.time) [\(message.category)] \(padding) \(message.type.icon) [\(message.type.rawValue)] <\(message.fileName):\(message.line)> \(message.text)"
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: true)
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: false)
	}
}
