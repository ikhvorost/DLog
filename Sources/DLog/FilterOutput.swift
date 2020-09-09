//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 30.08.2020.
//


import Foundation

// https://academy.realm.io/posts/nspredicate-cheatsheet/


class FilterOutput : LogOutput {
	let predicate: NSPredicate
	
	init(query: String) {
		predicate = NSPredicate(format: query)
	}
	
	override func log(message: LogMessage) -> String? {
		predicate.evaluate(with: message)
			? super.log(message: message)
			: nil
	}
	
	override public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		predicate.evaluate(with: scope)
			? super.scopeEnter(scope: scope, scopes: scopes)
			: nil
	}
	
	override public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		predicate.evaluate(with: scope)
			? super.scopeLeave(scope: scope, scopes: scopes)
			: nil
	}
}
