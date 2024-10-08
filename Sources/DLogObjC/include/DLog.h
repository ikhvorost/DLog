@import Foundation;
@import DLog;


#define DLOG_VARGS_(_3, _2, _1, N, ...) N
#define DLOG_VARGS(...) DLOG_VARGS_(__VA_ARGS__, 3, 2, 1, 0)
#define DLOG_CONCAT_(a, b) a##b
#define DLOG_CONCAT(a, b) DLOG_CONCAT_(a, b)

#define DLOG_LOCATION fileID(NSBundle.mainBundle, @(__FILE__)), @(__FILE__), @(__FUNCTION__), __LINE__
#define DLOG_PARAMS(format, ...) [NSString stringWithFormat:(format) ?: @"", ##__VA_ARGS__], DLOG_LOCATION

#define log(format, ...) log(DLOG_PARAMS(format, ##__VA_ARGS__))

#define trace_2(format, ...) trace(DLOG_PARAMS((format), ##__VA_ARGS__))
#define trace_1(format) trace_2(format)
#define trace_0() trace_1(nil)
#define trace_x(x,a,b,FUNC, ...)  FUNC
#define trace(...) trace_x(,##__VA_ARGS__, trace_2(__VA_ARGS__), trace_1(__VA_ARGS__), trace_0(__VA_ARGS__))

#define debug(format, ...) debug(DLOG_PARAMS(format, ##__VA_ARGS__))
#define info(format, ...) info(DLOG_PARAMS(format, ##__VA_ARGS__))
#define warning(format, ...) warning(DLOG_PARAMS(format, ##__VA_ARGS__))
#define error(format, ...) error(DLOG_PARAMS(format, ##__VA_ARGS__))

#define assert_3(condition, format, ...) assertion((condition), DLOG_PARAMS(format, ##__VA_ARGS__))
#define assert_2(condition, format) assert_3((condition), format)
#define assert_1(condition) assert_2((condition), nil)
#define assertion(...) DLOG_CONCAT(assert_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)

#define fault(format, ...) fault(DLOG_PARAMS(format, ##__VA_ARGS__))

#define scope_2(name, block) scope((name), (block))
#define scope_1(name) scope_2((name), nil)
#define scope(...) DLOG_CONCAT(scope_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)

#define interval_2(name, block) interval((name), DLOG_LOCATION, (block))
#define interval_1(name) interval_2((name), nil)
#define interval(...) DLOG_CONCAT(interval_, DLOG_VARGS(__VA_ARGS__))(__VA_ARGS__)


typedef LogItem* _Nullable (^_Nonnull LogBlock)(NSString* _Nullable, NSString* _Nonnull, NSString* _Nonnull, NSString* _Nonnull, NSUInteger);
typedef LogItem* _Nullable (^_Nonnull AssertBlock)(BOOL, NSString* _Nullable, NSString* _Nonnull, NSString* _Nonnull, NSString* _Nonnull, NSUInteger);
typedef LogScope* _Nonnull (^_Nonnull ScopeBlock)(NSString* _Nonnull, void (^_Nullable)(LogScope* _Nonnull));
//typedef LogInterval* _Nonnull (^_Nonnull IntervalBlock)(NSString* _Nonnull, NSString* _Nonnull, NSString* _Nonnull, NSString* _Nonnull, NSUInteger, void (^_Nullable)());

extern NSString* _Nonnull fileID(NSBundle* _Nonnull bundle, NSString* _Nonnull file);

@interface Log (PropertyWrapper)

@property (nonatomic, readonly) LogBlock log;
@property (nonatomic, readonly) LogBlock trace;
@property (nonatomic, readonly) LogBlock debug;
@property (nonatomic, readonly) LogBlock info;
@property (nonatomic, readonly) LogBlock warning;
@property (nonatomic, readonly) LogBlock error;
@property (nonatomic, readonly) AssertBlock assertion;
@property (nonatomic, readonly) LogBlock fault;
@property (nonatomic, readonly) ScopeBlock scope;
//@property (nonatomic, readonly) IntervalBlock interval;

@end
