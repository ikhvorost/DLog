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

	private func writeScope(scope: LogScope, scopes: [LogScope], start: Bool) -> String {
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
		
		return "\(time) [\(scope.category)] \(padding) [\(scope.name)] \(ms ?? "")"
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String {
		var padding = ""
		if let maxlevel = message.scopes.last?.level {
			for level in 1...maxlevel {
				let scope = message.scopes.first(where: { $0.level == level })
				padding += scope != nil ? "|\t" : "\t"
			}
		}
		
		let time = Self.dateFormatter.string(from: message.time)
		return "\(time) [\(message.category)] \(padding) \(message.type.icon) [\(message.type.title)] <\(message.fileName):\(message.line)> \(message.text)"
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: true)
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		return writeScope(scope: scope, scopes: scopes, start: false)
	}
	
	override func intervalBegin(interval: LogInterval) {
	}
	
	override func intervalEnd(interval: LogInterval) -> String {
		let duration = stringFromTime(interval: interval.duration)
		let minDuration = stringFromTime(interval: interval.minDuration)
		let maxDuration = stringFromTime(interval: interval.maxDuration)
		let avgDuration = stringFromTime(interval: interval.avgDuration)
		let text = "[\(interval.name)] Count: \(interval.count), Total: \(duration)s, Min: \(minDuration)s, Max: \(maxDuration)s, Avg: \(avgDuration)s"
		
		let message = LogMessage(category: interval.category, text: text, type: .interval, time: Date(), fileName: interval.file, function: interval.function, line: interval.line, scopes: interval.scopes)
		return log(message: message)
	}
}
