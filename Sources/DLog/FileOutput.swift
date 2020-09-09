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
		let fileManager = FileManager.default
		try? fileManager.removeItem(atPath: filePath)
		fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
		
		file = FileHandle(forWritingAtPath: filePath)
		
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
		write(super.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		write(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		write(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalEnd(interval: LogInterval) -> String? {
		write(super.intervalEnd(interval: interval))
	}
}