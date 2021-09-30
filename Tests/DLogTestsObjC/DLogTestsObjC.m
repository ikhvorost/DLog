#import <XCTest/XCTest.h>

@import DLogObjC;

#define let __auto_type const
#define var __auto_type

@implementation NSString (RegularExpression)

- (BOOL)match:(NSString*)pattern {
	return [self rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

@end

void testAll(id<LogProtocol> logger, NSString *category) {
	XCTAssert([logger.log(@"log") match:@" log"]);
	XCTAssert([logger.trace(@"trace") match:@" trace"]);
	XCTAssert([logger.debug(@"debug") match:@" debug"]);
	XCTAssert([logger.info(@"info") match:@" info"]);
	XCTAssert([logger.warning(@"warning") match:@" warning"]);
	XCTAssert([logger.error(@"error") match:@" error"]);
	XCTAssertNil(logger.assert(YES, @"assert"));
	XCTAssert([logger.assert(NO, @"assert") match:@" assert"]);
	XCTAssert([logger.fault(@"fault") match:@" fault"]);
}

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
	
	testAll(logger, nil);
}

- (void)test_Disabled {
	let logger = DLog.disabled;
	XCTAssertNotNil(logger);
	
	XCTAssertNil(logger.log(@"disabled"));
}

- (void)test_Category {
	let logger = [DLog new];
	let category = logger[@"NET"];
	XCTAssertNotNil(category);
	
	testAll(category, @"NET");
}
 
@end
