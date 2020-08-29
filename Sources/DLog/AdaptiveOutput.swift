//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class AdaptiveOutput : LogOutput {
	let output: LogOutput
	
	static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	public init() {
		if DLog.isDebug {
			output = StandardOutput()
		}
		else {
			output  = Self.isTerminal ? ColoredOutput() : OSLogOutput()
		}
	}

	// MARK: - LogOutput
	
	public func log(message: LogMessage) -> String {
		output.log(message: message)
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		output.scopeEnter(scope: scope, scopes: scopes)
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		output.scopeLeave(scope: scope, scopes: scopes)
	}
	
	public func intervalBegin(interval: LogInterval) {
		output.intervalBegin(interval: interval)
	}
	
	public func intervalEnd(interval: LogInterval) -> String {
		output.intervalEnd(interval: interval)
	}
}
