#ifndef CORDOVA_CBLITE_DATABASE_LIVEQUERY_H
#define CORDOVA_CBLITE_DATABASE_LIVEQUERY_H

#import "CBLiteDatabase.h"
#import "CBLiteLiveQuery.h"

@interface CBLiteDatabase(LiveQuery)

@property NSMutableDictionary<NSString*, CBLiteLiveQuery*> *liveQueries;

-(void)liveQuery:(CDVInvokedUrlCommand *)command;

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command;

@end

#endif
