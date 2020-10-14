//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 14.10.2020.
//

import Foundation
import os.log

@objc
public enum LogType : Int {
	case trace
	case info
	case interval
	case scope
	case debug
	case error
	case assert
	case fault
	
	private static let icons: [LogType : String] = [
		.trace : "◽️",
		.info : "✅",
		.debug : "▶️",
		.error : "⚠️",
		.assert : "🅰️",
		.fault : "🆘",
		.interval : "🕒",
		.scope : "#️⃣",
	]
	
	var icon: String {
		Self.icons[self]!
	}
	
	private static let titles: [LogType : String] = [
		.trace : "TRACE",
		.info : "INFO",
		.interval : "INTERVAL",
		.debug : "DEBUG",
		.error : "ERROR",
		.assert : "ASSERT",
		.fault : "FAULT",
	]
	
	var title: String {
		Self.titles[self]!
	}
}

@objcMembers
public class LogItem : NSObject {
	public var time: Date?
	public let category: String
	public let type: LogType
	public let fileName: String
	public let funcName: String
	public let line: UInt
	public let text: String
	
	public init(time: Date? = nil, category: String, type: LogType, fileName: String, funcName: String, line: UInt, text: String) {
		self.time = time
		self.category = category
		self.type = type
		self.fileName = fileName
		self.funcName = funcName
		self.line = line
		self.text = text
	}
}

public class LogMessage : LogItem {
	let scopes: [LogScope]
	
	public init(time: Date, category: String, type: LogType, fileName: String, funcName: String, line: UInt, text: String, scopes: [LogScope]) {
		self.scopes = scopes
		super.init(time: time, category: category, type: type, fileName: fileName, funcName: funcName, line: line, text: text)
	}
}

public class LogScope : LogItem {
	weak var log: DLog!
	let uid = UUID()
	var level: Int = 1
	var os_state = os_activity_scope_state_s()
	var entered = false
	
	init(log: DLog, category: String, fileName: String, funcName: String, line: UInt, text: String) {
		self.log = log
		super.init(category: category, type: .scope, fileName: fileName, funcName: funcName, line: line, text: text)
	}
	
	deinit {
		log.leave(scope: self)
	}
	
	public func enter() {
		guard !entered else { return }
		entered = true
		
		time = Date()
		log.enter(scope: self)
	}
	
	public func leave() {
		guard entered else { return }
		entered = false
		log.leave(scope: self)
	}
}

public class LogInterval : LogItem {
	weak var log: DLog!
	let name: StaticString
	let scopes: [LogScope]
	
	var count = 0
	var duration: TimeInterval = 0
	var minDuration: TimeInterval = 0
	var maxDuration: TimeInterval = 0
	var avgDuration: TimeInterval = 0
	
	var id : String {
		"\(fileName):\(line)"
	}
	
	// SignpostID
	private var _signpostID: Any? = nil
	@available(OSX 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	init(log: DLog, category: String, fileName: String, funcName: String, line: UInt, name: StaticString, scopes: [LogScope]) {
		self.log = log
		self.name = name
		self.scopes = scopes
		
		super.init(category: category, type: .interval, fileName: fileName, funcName: funcName, line: line, text: "\(name)")
	}
	
	public func begin() {
		guard time == nil else { return }
	
		time = Date()
		
		log.begin(interval: self)
	}
	
	public func end() {
		guard let time = time else { return }
		
		let timeInterval = time.timeIntervalSinceNow
		let interval = -timeInterval
		count += 1
		duration += interval
		if minDuration == 0 || minDuration > interval {
			minDuration = interval
		}
		if maxDuration == 0 || maxDuration < interval {
			maxDuration = interval
		}
		avgDuration = duration / Double(count)
		
		self.time = nil
		
		log.end(interval: self)
	}
	
	public func event() {
		
	}
}
