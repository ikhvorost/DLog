//
//  Filter.swift
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

/// Middleware output for filtering
///
public class Filter : LogOutput {
	private let predicate: (LogItem) -> Bool
	
	/// Initializes a filter output that evaluates using a specified block object.
	///
	/// Represents a pipe middleware output that can filter log messages by available fields of an evaluated object.
	///
	///		// Logs debug messages only
	///		let log = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)
	///
	/// - Parameters:
	/// 	- block: The block is applied to the object to be evaluated.
	///
	public init(block: @escaping (LogItem) -> Bool) {
		predicate = block
		super.init(source: nil)
	}
	
	// MARK: - LogOutput
	
	override func log(item: LogItem, scopes: [LogScope]) -> String? {
		let text = super.log(item: item, scopes: scopes)
		return predicate(item) ? text : nil
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		let text = super.scopeEnter(scope: scope, scopes: scopes)
		return predicate(scope) ? text : nil
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		let text = super.scopeLeave(scope: scope, scopes: scopes)
		return predicate(scope) ? text : nil
	}
	
	override func intervalEnd(interval: LogInterval, scopes: [LogScope]) -> String? {
		let text = super.intervalEnd(interval: interval, scopes: scopes)
		return predicate(interval) ? text : nil
	}
}
