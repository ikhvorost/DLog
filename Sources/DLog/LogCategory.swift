//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 14.10.2020.
//


import Foundation


public class LogCategory {
	let log: DLog
	let category: String
	
	public init(log: DLog, category: String) {
		self.log = log
		self.category = category
	}
	
	@discardableResult
	public func trace(_ text: String? = nil, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.trace(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.info(text, category: category, file: file, function: function, line: line)
	}
		
	@discardableResult
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.debug(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func error(_ error: Error, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.error(error, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.fault(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.assert(value, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
		log.scope(text, category: category, file: file, function: function, line: line, closure: closure)
	}
	
	@discardableResult
	public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		log.interval(name, category: category, file: file, function: function, line: line, closure: closure)
	}
}
