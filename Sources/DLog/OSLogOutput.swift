//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation
import os
import os.log
import os.activity

public class OSLogOutput : LogOutput {
	
	// Formatters
	//	Type Format String Example Output
	//	time_t %{time_t}d 2016-01-12 19:41:37
	//	timeval %{timeval}.*P 2016-01-12 19:41:37.774236
	//	timespec %{timespec}.*P 2016-01-12 19:41:37.774236823
	//	errno %{errno}d Broken pipe
	//	uuid_t %{uuid_t}.16P
	//	%{uuid_t}.*P 10742E39-0657-41F8-AB99-878C5EC2DCAA
	//	sockaddr %{network:sockaddr}.*P fe80::f:86ff:fee9:5c16
	//	17.43.23.87
	//	in_addr %{network:in_addr}d 17.43.23.87
	//	in6_addr %{network:in6_addr}.16P fe80::f:86ff:fee9:5c16
	
	// Handle to dynamic shared object
	private static var dso = UnsafeMutableRawPointer(mutating: #dsohandle)
	
	// Load the symbol dynamically, since it is not exposed to Swift...
	// see activity.h and dlfcn.h
	// https://nsscreencast.com/episodes/347-activity-tracing-in-swift
	// https://gist.github.com/zwaldowski/49f61292757f86d7d036a529f2d04f0c
	private static let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
	private static let OS_ACTIVITY_NONE = unsafeBitCast(dlsym(RTLD_DEFAULT, "_os_activity_none"), to: os_activity_t.self)
	private static let OS_ACTIVITY_CURRENT = unsafeBitCast(dlsym(RTLD_DEFAULT, "_os_activity_current"), to: os_activity_t.self)
	
	static let types: [LogType : OSLogType] = [
		.trace : .default,
		.info : .info,
		.debug : .debug,
		.error : .error,
		.assert : .fault,
		.fault : .fault,
	]

	private var log: OSLog?
	
	private func oslog(category: String) -> OSLog {
		synchronized(self) {
			if log == nil {
				let subsystem = Bundle.main.bundleIdentifier ?? ""
				log = OSLog(subsystem: subsystem, category: category)
			}
			return log!
		}
	}
	
	// MARK: - LogOutput
	
	override public func log(message: LogMessage) -> String? {
		let log = oslog(category: message.category)
		
		let location = "<\(message.fileName):\(message.line)>"
		let type = Self.types[message.type]!
		os_log("%s %s %s", dso: Self.dso, log: log, type: type, message.type.icon, location, message.text)
		
		return super.log(message: message)
	}
	
	override public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		let activity = _os_activity_create(Self.dso, strdup(scope.text), Self.OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT)
		os_activity_scope_enter(activity, &scope.os_state)
		
		return super.scopeEnter(scope: scope, scopes: scopes)
	}
	
	override public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		os_activity_scope_leave(&scope.os_state);
		
		return super.scopeLeave(scope: scope, scopes: scopes)
	}
	
	override public func intervalBegin(interval: LogInterval) {
		super.intervalBegin(interval: interval)
		
		guard #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) else { return }
		
		let log = oslog(category: interval.category)
		if interval.signpostID == nil {
			interval.signpostID = OSSignpostID(log: log)
		}

		os_signpost(.begin, log: log, name: interval.name, signpostID: interval.signpostID!)
	}
	
	override public func intervalEnd(interval: LogInterval) -> String? {
		if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
			let log = oslog(category: interval.category)
			os_signpost(.end, log: log, name: interval.name, signpostID: interval.signpostID!)
		}
		return super.intervalEnd(interval: interval)
	}
}
