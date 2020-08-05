//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class AdaptiveOutput : LogOutput {
	let output: LogOutput
	
	static var isDebug : Bool {
		var info = kinfo_proc()
		var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		var size = MemoryLayout<kinfo_proc>.stride
		let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		assert(junk == 0, "sysctl failed")
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
	
	static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	public init() {
		if Self.isDebug {
			output = StandardOutput()
		}
		else {
			output  = Self.isTerminal ? ColoredOutput() : OSLogOutput()
		}
	}
	
	public func log(message: LogMessage) -> String {
		output.log(message: message)
		
		return ""
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		return output.scopeEnter(scope: scope, scopes: scopes)
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String {
		return output.scopeLeave(scope: scope, scopes: scopes)
	}
}
