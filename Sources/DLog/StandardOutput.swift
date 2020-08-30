//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation


public class StandardOutput : LogOutput {
	
	override init() {
		super.init()
		output = TextOutput()
	}
	
	func echo(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			print(str)
		}
		return text
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String? {
		echo(output.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		echo(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String? {
		echo(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalBegin(interval: LogInterval) {
	}
	
	override func intervalEnd(interval: LogInterval) -> String? {
		echo(output.intervalEnd(interval: interval))
	}
}
