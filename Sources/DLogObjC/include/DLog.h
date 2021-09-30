@import DLog;

#define STATIC_CONST(type, code) ^type() { \
	static type object; \
	static dispatch_once_t onceToken; \
	dispatch_once(&onceToken, ^{ \
		object = code; \
	}); \
	return object; \
};

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

