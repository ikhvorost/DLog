@import DLog;


#define DLOG_VARGS_(_10, _9, _8, _7, _6, _5, _4, _3, _2, _1, N, ...) N
#define DLOG_VARGS(...) DLOG_VARGS_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define DLOG_CONCAT_(a, b) a##b
#define DLOG_CONCAT(a, b) DLOG_CONCAT_(a, b)

#define DLOG_PARAMS(format, ...) ((format) != nil ? [NSString stringWithFormat: (format), ##__VA_ARGS__] : @""),\
	@(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__

#define log(format, ...) log(DLOG_PARAMS(format, ##__VA_ARGS__))

#define trace(format, ...) trace(DLOG_PARAMS(format, ##__VA_ARGS__), NSThread.callStackReturnAddresses)
//#define trace() trace(nil)
//#define trace_2(format, ...) trace(DLOG_PARAMS(format, ##__VA_ARGS__))
//#define trace_1(format, ...) trace(DLOG_PARAMS(format, ##__VA_ARGS__))
//#define trace_0() trace_1(nil)
//#define trace(...) DLOG_CONCAT(trace_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)
//#define trace(...) trace(DLOG_PARAMS(format, ##__VA_ARGS__), NSThread.callStackReturnAddresses)

#define debug(format, ...) debug(DLOG_PARAMS(format, ##__VA_ARGS__))
#define info(format, ...) info(DLOG_PARAMS(format, ##__VA_ARGS__))
#define warning(format, ...) warning(DLOG_PARAMS(format, ##__VA_ARGS__))
#define error(format, ...) error(DLOG_PARAMS(format, ##__VA_ARGS__))

#ifdef assert
#undef assert
#endif
#define assert(c, format, ...) assert((c), DLOG_PARAMS(format, ##__VA_ARGS__))

#define fault(format, ...) fault(DLOG_PARAMS(format, ##__VA_ARGS__))

#define scope_2(name, block) scope((name),  @(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__, (block))
#define scope_1(name) scope_2((name), nil)
#define scope(...) DLOG_CONCAT(scope_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)

#define interval_2(name, block) interval((name),  @(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__, (block))
#define interval_1(name) interval_2((name), nil)
#define interval(...) DLOG_CONCAT(interval_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)


typedef NSString* (^LogBlock)(NSString*, NSString*, NSString*, NSUInteger);
typedef NSString* (^TraceBlock)(NSString*, NSString*, NSString*, NSUInteger, NSArray<NSNumber*>*);
typedef NSString* (^AssertBlock)(BOOL, NSString*, NSString*, NSString*, NSUInteger);
typedef LogScope* (^ScopeBlock)(NSString*, NSString*, NSString*, NSUInteger, void (^)(LogScope*));
typedef LogInterval* (^IntervalBlock)(NSString*, NSString*, NSString*, NSUInteger, void (^)());


@interface LogProtocol (PropertyWrapper)

@property (nonatomic, readonly) LogBlock log;
@property (nonatomic, readonly) TraceBlock trace;
@property (nonatomic, readonly) LogBlock debug;
@property (nonatomic, readonly) LogBlock info;
@property (nonatomic, readonly) LogBlock warning;
@property (nonatomic, readonly) LogBlock error;
@property (nonatomic, readonly) AssertBlock assert;
@property (nonatomic, readonly) LogBlock fault;
@property (nonatomic, readonly) ScopeBlock scope;
@property (nonatomic, readonly) IntervalBlock interval;

@end
