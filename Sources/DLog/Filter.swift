//
//  Filter
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/30.
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

// https://academy.realm.io/posts/nspredicate-cheatsheet/


public class Filter : LogOutput {
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
