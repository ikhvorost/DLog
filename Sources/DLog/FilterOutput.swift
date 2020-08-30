//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 30.08.2020.
//

import Foundation

class FilterOutput : LogOutput {
//	let category: String
//	let text: String
	let type: LogType?
//	let time: Date
//	let fileName: String
//	let function: String
//	let line: UInt
//	let scopes: [LogScope]
	
	init(type: LogType?) {
		self.type = type
	}
	
	override func log(message: LogMessage) -> String? {
		return message.type == type ? output.log(message: message) : nil
	}
}
