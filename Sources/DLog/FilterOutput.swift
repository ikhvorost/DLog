//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 30.08.2020.
//


import Foundation

// https://academy.realm.io/posts/nspredicate-cheatsheet/


public class FilterOutput : LogOutput {
	private let predicate: NSPredicate
	
	// "text CONTAINS[c] 'hello'"
	init(query: String) {
		predicate = NSPredicate(format: query)
	}
	
	init(block: @escaping (LogItem) -> Bool) {
		predicate = NSPredicate { (obj, _) in
			if let item = obj as? LogItem {
				return block(item)
			}
			return true
		}
	}
	
	// MARK: - LogOutput
	
	public override func log(message: LogMessage) -> String? {
		let text = super.log(message: message)
		return predicate.evaluate(with: message) ? text : nil
	}
	
	override public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		let text = super.scopeEnter(scope: scope, scopes: scopes)
		return predicate.evaluate(with: scope) ? text : nil
	}
	
	override public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		let text = super.scopeLeave(scope: scope, scopes: scopes)
		return predicate.evaluate(with: scope) ? text : nil
	}
	
	override public func intervalEnd(interval: LogInterval) -> String? {
		let text = super.intervalEnd(interval: interval)
		return predicate.evaluate(with: interval) ? text : nil
	}
}
