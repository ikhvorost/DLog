@import DLog;

#define STATIC_CONST(type, code) ^type() { \
	static type object; \
	static dispatch_once_t onceToken; \
	dispatch_once(&onceToken, ^{ \
		object = (code); \
	}); \
	return object; \
};


#define VARGS_(_10, _9, _8, _7, _6, _5, _4, _3, _2, _1, N, ...) N
#define VARGS(...) VARGS_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define CONCAT_(a, b) a##b
#define CONCAT(a, b) CONCAT_(a, b)

#define __DLOG_PARAMS(format, ...) ((format) != nil ? [NSString stringWithFormat: (format), ##__VA_ARGS__] : @""),\
	@(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__

#define log(format, ...) log(__DLOG_PARAMS(format, ##__VA_ARGS__))
#define trace(format, ...) trace(__DLOG_PARAMS(format, ##__VA_ARGS__), NSThread.callStackReturnAddresses)
#define debug(format, ...) debug(__DLOG_PARAMS(format, ##__VA_ARGS__))
#define info(format, ...) info(__DLOG_PARAMS(format, ##__VA_ARGS__))
#define warning(format, ...) warning(__DLOG_PARAMS(format, ##__VA_ARGS__))
#define error(format, ...) error(__DLOG_PARAMS(format, ##__VA_ARGS__))
#define assert(c, format, ...) assert((c), __DLOG_PARAMS(format, ##__VA_ARGS__))
#define fault(format, ...) fault(__DLOG_PARAMS(format, ##__VA_ARGS__))

#define scope_2(name, block) scope((name),  @(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__, (block))
#define scope_1(name) scope_2(name, nil)
#define scope(...) CONCAT(scope_, VARGS(__VA_ARGS__))(__VA_ARGS__)
