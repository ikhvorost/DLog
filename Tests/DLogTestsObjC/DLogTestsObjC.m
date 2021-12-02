#import <XCTest/XCTest.h>

@import DLogObjC;

#define let __auto_type const
#define var __auto_type

#pragma mark - Extentions

@implementation NSString (RegularExpression)

- (BOOL)match:(NSString*)pattern {
	return [self rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

@end

@implementation NSThread (Delay)

+ (void)sleep {
    [self sleepForTimeInterval: 0.25];
}

@end

#pragma mark - Utils

#define CategoryTag @"\\[DLOG\\]"
#define Padding @"[\\|\\s]+"
#define LevelTag @"\\[\\S+\\] "
#define Location @"<DLogTestsObjC:[0-9]+> "

static NSString* matchString(NSString* category, NSString* text) {
	return [NSString stringWithFormat:@"%@" Padding LevelTag Location @"%@", (category ?: CategoryTag), text];
}

typedef void (^VoidBlock)(void);

static NSString* readStream(int file, FILE* stream, VoidBlock block) {
    let result = [NSMutableString new];
    
    let pipe = [NSPipe new];
    
    let original = dup(file);
    setvbuf(stream, nil, _IONBF, 0);
    dup2(pipe.fileHandleForWriting.fileDescriptor, file);
    
    pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle* handle) {
        let text = [[NSString alloc] initWithData:handle.availableData encoding: NSUTF8StringEncoding];
        [result appendString:text];
    };
    
    block();
    
    [NSThread sleep];
    
    // Revert
    fflush(stream);
    dup2(original, file);
    close(original);
    
    // Print
    printf("%s\n", result.UTF8String);
    
    return result;
}

static NSString* read_stdout(VoidBlock block) {
    return readStream(STDOUT_FILENO, stdout, block);
}

static NSString* read_stderr(VoidBlock block) {
    return readStream(STDERR_FILENO, stderr, block);
}

#pragma mark - Tests

static void testAll(id<LogProtocol> logger, NSString *category) {
	XCTAssertNotNil(logger);
    
    XCTAssert([logger.log(@"log") match:matchString(category, @"log")]);
    XCTAssert([logger.log(@"log %d", 123) match:matchString(category, @"log 123")]);
    
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

- (void)test_Levels {
	let logger = [DLog new];
	XCTAssertNotNil(logger);
	
	testAll(logger, nil);
}

- (void)test_Scope {
	let logger = [DLog new];
	XCTAssertNotNil(logger);
	
	logger.scope(@"Scope 1", ^(LogScope* scope) {
		testAll(scope, nil);
	});
	
	let scope = logger.scope(@"Scope 2");
	XCTAssertNotNil(scope);
	[scope enter];
	
	testAll(scope, nil);

	[scope leave];
}
 
- (void)test_Interval {
	let logger = [DLog new];
	XCTAssertNotNil(logger);
	
	logger.interval(@"Interval 1", ^{
		logger.debug(@"debug");
	});
}

- (void)test_Category {
    let logger = [DLog new];
    XCTAssertNotNil(logger);
    
    let category = logger[@"NET"];
    XCTAssertNotNil(category);
    
    testAll(category, @"\\[NET\\]");
}

- (void)test_AllOutputs {
    let outputs = @[
        LogOutput.textPlain,
        LogOutput.textEmoji,
        LogOutput.textColored,
        LogOutput.stdOut,
        LogOutput.stdErr,
        LogOutput.oslog,
        [LogOutput oslog:@"com.dlog.objc"],
        [LogOutput filter:^BOOL(LogItem* logItem) {
            return logItem.type == LogTypeDebug;
        }],
        [LogOutput file:@"dlog.txt" append:NO],
        [LogOutput net],
        [LogOutput net:@"dlog"],
    ];
    
    for (LogOutput* output in outputs) {
        let logger = [[DLog alloc] initWithOutput:output];
        XCTAssertNotNil(logger);
        
        logger.debug(@"debug");
    }
    
    [NSThread sleep];
}

- (void)test_Pipeline {
}

- (void)test_Filter {
    let filter = [LogOutput filter:^BOOL(LogItem* logItem) {
        if ([logItem isKindOfClass:LogScope.class]) {
            return [logItem.text() isEqualToString:@"Scope"];
        }
        
        return
            [logItem.time compare:NSDate.now] == NSOrderedAscending &&
            [logItem.category isEqualToString:@"DLOG"] &&
            [logItem._scope.text() isEqualToString:@"Scope"] &&
            logItem.type == LogTypeDebug &&
            [logItem.fileName isEqualToString:@"DLogTestsObjC"] &&
            [logItem.funcName isEqualToString:@"-[DLogTestsObjC test_Filter]"] &&
            (logItem.line > __LINE__) &&
            [logItem.text() isEqualToString:@"debug"];
    }];
    XCTAssertNotNil(filter);
    
    let logger = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, filter, LogOutput.stdOut]];
    XCTAssertNotNil(logger);
    
    let scope = logger.scope(@"Scope");
    XCTAssertNotNil(scope);
    [scope enter];
    
    XCTAssert([scope.debug(@"debug") match:matchString(nil, @"debug")]);
    XCTAssertFalse([scope.log(@"log") match:matchString(nil, @"log")]);
    
    [scope leave];
}

- (void)test_Disabled {
    let logger = DLog.disabled;
    XCTAssertNotNil(logger);
    
    XCTAssertNil(logger.log(@"log"));
}

@end
