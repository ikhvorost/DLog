//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 14.10.2020.
//

import Foundation

/// Base output class
public class LogOutput : NSObject {
	public static var text: TextOutput { TextOutput() }
	public static var textColor: TextOutput { TextOutput(color: true) }
	public static var stdout: StandardOutput { StandardOutput() }
	public static var adaptive: AdaptiveOutput { AdaptiveOutput() }
	public static var oslog: OSLogOutput { OSLogOutput() }
	public static var net: NetOutput { net() }
	
	public static func filter(_ block: @escaping (LogItem) -> Bool) -> FilterOutput { FilterOutput(block: block) }
	public static func file(_ filePath: String) -> FileOutput { FileOutput(filePath: filePath) }
	public static func net(name: String = "DLog", debug: Bool = false) -> NetOutput { NetOutput(name: name, debug: debug) }

	var output: LogOutput!
	
	@discardableResult
	public func log(message: LogMessage) -> String? {
		return output != nil
			? output.log(message: message)
			: nil
	}
	
	@discardableResult
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		return output != nil
			? output.scopeEnter(scope: scope, scopes: scopes)
			: nil
	}
	
	@discardableResult
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		return output != nil
			? output.scopeLeave(scope: scope, scopes: scopes)
			: nil
	}
	
	public func intervalBegin(interval: LogInterval) {
		if output != nil {
			output.intervalBegin(interval: interval)
		}
	}
	
	@discardableResult
	public func intervalEnd(interval: LogInterval) -> String? {
		return output != nil
			? output.intervalEnd(interval: interval)
			: nil
	}
}

// Forward pipe
precedencegroup ForwardPipe {
	associativity: left
}
infix operator => : ForwardPipe

extension LogOutput {
	// Forward pipe
	public static func => (left: LogOutput, right: LogOutput) -> LogOutput {
		right.output = left
		return right
	}
}
