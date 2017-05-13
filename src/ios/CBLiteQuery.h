#ifndef CORDOVA_CBLITE_QUERY_H
#define CORDOVA_CBLITE_QUERY_H

#import "CBLQuery.h"

@interface CBLiteQuery : NSObject
{

}

@property CBLQuery* q;

@property NSMutableDictionary* options;

-(id)init:(CBLQuery*)query withParams:(NSDictionary*)params;

-(NSMutableDictionary*)results:(CBLQueryEnumerator*)results;

-(NSMutableDictionary*)run:(NSError*)error;

@end

#endif
