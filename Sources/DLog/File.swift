//
//  File
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/12.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation


public class File : LogOutput {
	private let file: FileHandle?
	private let queue = DispatchQueue(label: "File")
	
	public init(path: String, append: Bool = false, source: LogOutput = .textPlain) {
		let fileManager = FileManager.default
		if append == false {
			try? fileManager.removeItem(atPath: path)
		}
		
		if fileManager.fileExists(atPath: path) == false {
			let dir = NSString(string: path).deletingLastPathComponent
			try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
			
			fileManager.createFile(atPath: path, contents: nil, attributes: nil)
		}
		
		file = FileHandle(forWritingAtPath: path)
		
		if append {
			file?.seekToEndOfFile()
		}
		
		super.init(source: source)
	}
	
	deinit {
		file?.closeFile()
	}
	
	private func write(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			queue.async {
				if let data = (str + "\n").data(using: .utf8) {
					self.file?.write(data)
				}
			}
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
