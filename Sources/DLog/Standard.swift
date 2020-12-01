//
//  Standard
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/03.
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


public class Standard : LogOutput {
	
	public enum Stream {
		case out
		case err
	}
	
	let stream: Stream
	
	public init(stream: Stream = .out, source: LogOutput = .text) {
		self.stream = stream
		
		super.init(source: source)
	}
	
	private func echo(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			switch stream {
				case .out:
					fputs(str + "\n", Darwin.stdout)
					
				case .err:
					fputs(str + "\n", Darwin.stderr)
			}
		}
		return text
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String? {
		echo(super.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		echo(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String? {
		echo(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalEnd(interval: LogInterval) -> String? {
		echo(super.intervalEnd(interval: interval))
	}
}
