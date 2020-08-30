//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 12.08.2020.
//

import Foundation

class FileOutput : LogOutput {
	let file: FileHandle?
	
	init(filePath: String) {
		if !FileManager.default.fileExists(atPath: filePath) {
			FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
		}
		file = FileHandle(forWritingAtPath: filePath)
		file?.seekToEndOfFile()
		
		super.init()
		
		output = TextOutput()
	}
	
	deinit {
		file?.closeFile()
	}
	
	func write(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			let data = (str + "\n").data(using: .utf8)!
			file?.write(data)
		}
		return text
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String? {
		write(output.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		write(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		write(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalBegin(interval: LogInterval) {
	}
	
	override func intervalEnd(interval: LogInterval) -> String? {
		write(output.intervalEnd(interval: interval))
	}
}
