//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 03.08.2020.
//

import Foundation


public class StandardOutput : LogOutput {
	let output: TextOutput
	
	init(output: TextOutput = TextOutput()) {
		self.output = output
	}
	
	func echo(_ text: String) -> String {
		print(text)
		return text
	}
	
	public func log(message: LogMessage) -> String {
		echo(output.log(message: message))
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		echo(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		echo(output.scopeLeave(scope: scope, scopes: scopes))
	}
}
