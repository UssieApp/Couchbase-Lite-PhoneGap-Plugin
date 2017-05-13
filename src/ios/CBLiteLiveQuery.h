#ifndef CORDOVA_CBLITE_LIVE_QUERY_H
#define CORDOVA_CBLITE_LIVE_QUERY_H

#import "CBLiteNotify.h"
#import "CBLiteQuery.h"

#import "CBLQuery.h"

@interface CBLiteLiveQuery : CBLiteQuery;

@property CBLLiveQuery* live;

@property CBLiteNotify* notify;

-(id)init:(CBLQuery*)query withParams:(NSDictionary*)params;

-(void)runAndNotify:(CBLiteNotify*)note;

-(void)stop;

@end;

#endif
