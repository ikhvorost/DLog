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
		
		self.output = TextOutput()
	}
	
	func echo(_ text: String) -> String {
		if !text.isEmpty {
			print(text)
		}
		return text
	}
	
	// MARK: - LogOutput
	
	public override func log(message: LogMessage) -> String {
		echo(output.log(message: message))
	}
	
	public override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		echo(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	public override func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		echo(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	public override func intervalBegin(interval: LogInterval) {
	}
	
	public override func intervalEnd(interval: LogInterval) -> String {
		echo(output.intervalEnd(interval: interval))
	}
}
