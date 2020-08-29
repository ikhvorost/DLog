//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 12.08.2020.
//

import Foundation


class FileOutput : LogOutput {
	let output: TextOutput
	let file: FileHandle?
	
	init(filePath: String, output: TextOutput) {
		if !FileManager.default.fileExists(atPath: filePath) {
			FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
		}
		file = FileHandle(forWritingAtPath: filePath)
		file?.seekToEndOfFile()
		
		self.output = output
	}
	
	deinit {
		file?.closeFile()
	}
	
	func write(_ text: String) -> String {
		let data = (text + "\n").data(using: .utf8)!
		file?.write(data)
		return text
	}
	
	// MARK: - LogOutput
	
	public func log(message: LogMessage) -> String {
		write(output.log(message: message))
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		write(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		write(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	public func intervalBegin(interval: LogInterval) {
	}
	
	public func intervalEnd(interval: LogInterval) -> String {
		write(output.intervalEnd(interval: interval))
	}
}
