#import <XCTest/XCTest.h>

@import DLogObjC;

#define let __auto_type const
#define var __auto_type

@implementation NSString (RegularExpression)

- (BOOL)match:(NSString*)pattern {
	return [self rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

@end

@interface DLogTestsObjC : XCTestCase
@end
 
@implementation DLogTestsObjC

- (void)test_StaticConst {
	let array = STATIC_CONST(NSArray*, (@[@1, @2, @3, @4]));
	XCTAssert(array().count == 4);
}
 
- (void)test_Levels {
	let logger = [DLog new];
	XCTAssertNotNil(logger);
	
	XCTAssert([logger.log(@"log") match:@" log"]);
	XCTAssert([logger.trace(@"trace") match:@" trace"]);
	XCTAssert([logger.debug(@"debug") match:@" debug"]);
	XCTAssert([logger.info(@"info") match:@" info"]);
	XCTAssert([logger.warning(@"warning") match:@" warning"]);
	XCTAssert([logger.error(@"error") match:@" error"]);
	XCTAssert([logger.assert(NO, @"assert") match:@" assert"]);
	XCTAssert([logger.fault(@"fault") match:@" fault"]);
}

- (void)test_Disabled {
	let logger = DLog.disabled;
	XCTAssertNotNil(logger);
	
	let text = logger.log(@"disabled");
	XCTAssertNil(text);
}

- (void)test_Category {
	let logger = [DLog new];
	let category = logger[@"NET"];
	XCTAssertNotNil(category);
	
	//XCTAssert([category.debug(@"debug") match:@" debug"]);
}
 
@end
