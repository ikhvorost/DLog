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
	
	private func echo(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			print(str)
		}
		return text
	}
	
	// MARK: - LogOutput
	
	override public func log(message: LogMessage) -> String? {
		echo(super.log(message: message))
	}
	
	override public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		echo(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override public func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String? {
		echo(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override public func intervalEnd(interval: LogInterval) -> String? {
		echo(super.intervalEnd(interval: interval))
	}
}
