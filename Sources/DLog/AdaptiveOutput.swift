//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation

public class AdaptiveOutput : LogOutput {
	
	private static var isDebug : Bool {
		var info = kinfo_proc()
		var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		var size = MemoryLayout<kinfo_proc>.stride
		sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		//assert(junk == 0, "sysctl failed")
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
	
	private static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	override init() {
		super.init()
		
		if Self.isDebug {
			output = StandardOutput()
		}
		else {
			output = Self.isTerminal ? ColoredOutput() : OSLogOutput()
		}
	}
}
