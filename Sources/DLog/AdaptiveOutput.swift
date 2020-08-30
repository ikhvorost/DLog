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
	
	override init() {
		super.init()
		
		if DLog.isDebug {
			output = StandardOutput()
		}
		else {
			output = Self.isTerminal ? ColoredOutput() : OSLogOutput()
		}
	}
}
