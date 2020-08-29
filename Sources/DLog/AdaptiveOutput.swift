//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class AdaptiveOutput : LogOutput {
	static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	public override init() {
		super.init()
		
		if DLog.isDebug {
			output = StandardOutput()
		}
		else {
			output = Self.isTerminal ? ColoredOutput() : OSLogOutput()
		}
	}

	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String {
		output.log(message: message)
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		output.scopeEnter(scope: scope, scopes: scopes)
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		output.scopeLeave(scope: scope, scopes: scopes)
	}
	
	override func intervalBegin(interval: LogInterval) {
		output.intervalBegin(interval: interval)
	}
	
	override func intervalEnd(interval: LogInterval) -> String {
		output.intervalEnd(interval: interval)
	}
}
