//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class TextOutput : LogOutput {
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
		var padding = ""
		if let maxlevel = message.scopes.last?.level {
			for level in 1...maxlevel {
				let scope = message.scopes.first(where: { $0.level == level })
				padding += scope != nil ? "|\t" : "\t"
			}
		}
		
		let time = Self.dateFormatter.string(from: message.time)
		return "\(time) [\(message.category)] \(padding)\(message.type.icon) [\(message.type.title)] <\(message.fileName):\(message.line)> \(message.text)"
	}

	private func textScope(scope: LogScope, scopes: [LogScope], start: Bool) -> String {
		let time = Self.dateFormatter.string(from: Date())
		
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
		
		return "\(time) [\(scope.category)] \(padding) [\(scope.text)] \(ms ?? "")"
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
		
		let message = LogMessage(category: interval.category,
								 text: text,
								 type: .interval,
								 time: Date(),
								 fileName: interval.file,
								 functionName: interval.function,
								 line: interval.line,
								 scopes: interval.scopes)
		return textMessage(message: message)
	}
}
