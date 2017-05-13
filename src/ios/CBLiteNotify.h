#ifndef CORDOVA_CBLITE_NOTIFY_H
#define CORDOVA_CBLITE_NOTIFY_H

#import "CBLiteDatabase.h"

@interface CBLiteNotify : NSObject
{

}

@property CBLiteDatabase* db;

@property NSString* callbackId;

-(id)initOn:(CBLiteDatabase*)db forCallbackId:(NSString*)cid;

-(void)send:(NSDictionary*)out andKeep:(BOOL)keep;

-(void)onChange:(NSNotification*)note;

-(void)onSync:(NSNotification*)note;

@end

#endif
