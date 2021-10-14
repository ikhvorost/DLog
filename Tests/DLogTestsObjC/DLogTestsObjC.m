#import <XCTest/XCTest.h>

@import DLogObjC;

#define let __auto_type const
#define var __auto_type

@implementation NSString (RegularExpression)

- (BOOL)match:(NSString*)pattern {
	return [self rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

@end


#define CategoryTag @"\\[DLOG\\]"
#define Padding @"[\\|\\s]+"
#define LevelTag @"\\[\\S+\\] "
#define Location @"<DLogTestsObjC:[0-9]+> "

static NSString* matchString(NSString* category, NSString* text) {
	return [NSString stringWithFormat:@"%@" Padding LevelTag Location @"%@", (category ? category : CategoryTag), text];
}

static void testAll(id<LogProtocol> logger, NSString *category) {
	XCTAssert([logger.log(@"log") match:matchString(category, @"log")]);
	XCTAssert([logger.trace(@"trace") match:matchString(category, @"trace")]);
	XCTAssert([logger.debug(@"debug") match:matchString(category, @"debug")]);
	XCTAssert([logger.info(@"info") match:matchString(category, @"info")]);
	XCTAssert([logger.warning(@"warning") match:matchString(category, @"warning")]);
	XCTAssert([logger.error(@"error") match:matchString(category, @"error")]);
	XCTAssertNil(logger.assert(YES, @"assert"));
	XCTAssert([logger.assert(NO, @"assert") match:matchString(category, @"assert")]);
	XCTAssert([logger.fault(@"fault") match:matchString(category, @"fault")]);
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
	
	testAll(category, @"\\[NET\\]");
}

- (void)test_Scope {
	let logger = [DLog new];
	
	XCTAssertNotNil(logger);
	
	logger.scope(@"Scope 1", ^(LogScope* scope){
		testAll(scope, nil);
	});
	
	let scope = logger.scope(@"Scope 2");
	[scope enter];
	
	testAll(scope, nil);

	[scope leave];
}
 
@end
