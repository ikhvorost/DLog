//
//  Adaptive
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


public class Adaptive : LogOutput {
	
	private static var isDebug : Bool {
		var info = kinfo_proc()
		var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		var size = MemoryLayout<kinfo_proc>.stride
		sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		//assert(junk == 0, "sysctl failed")
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
	
	private static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	override init() {
		super.init()
		
		if Self.isDebug {
			output = (.textEmoji => .stdout)
		}
		else {
			output = Self.isTerminal
				? .textColored => .stdout
				: .net
		}
	}
}
