#import <Cordova/CDV.h>
#import "CBLDatabase.h"
#import "CBLQuery.h"

@interface CBLiteNotify : NSObject
{
    
}

@property NSString* dbName;

@property id<CDVCommandDelegate> delegate;

@property NSString* callbackId;

-(id)initOnDb:(NSString*)db
 withDelegate:(id<CDVCommandDelegate>)del
forCallbackId:(NSString*)cid;

-(void)send:(NSDictionary*)dict andKeep:(Boolean)keep;

-(void)onChange:(NSNotification*)note;

-(void)onSync:(NSNotification*)note;

@end

@interface CBLiteQuery : NSObject
{
    
}

@property CBLQuery* q;

@property NSMutableDictionary* options;

-(id)init:(CBLQuery*)query withParams:(NSDictionary*)params;

-(NSMutableDictionary*)run:(NSError*)error;

@end

@interface CBLiteLiveQuery : CBLiteQuery;

@property CBLLiveQuery* live;

@property CBLiteNotify* notify;

-(id)init:(CBLQuery*)query withParams:(NSDictionary*)params;

-(void)runAndNotify:(CBLiteNotify*)note;

-(void)stop;

@end;

@interface CBLite : CDVPlugin

@property NSMutableDictionary<NSString*, CBLiteLiveQuery*> *liveQueries;

#pragma mark - Internal Notify helpers

+(void)addNotify:(CBLiteNotify*)note;

+(void)removeNotify:(NSString*)key;

+(void)removeNotifiersFor:(NSString*)dbName;

#pragma mark - Manager

- (void) info: (CDVInvokedUrlCommand*)command;

- (void) openDatabase: (CDVInvokedUrlCommand*)command;

#pragma mark - Database handling

- (void) closeDatabase: (CDVInvokedUrlCommand*)command;

- (void) deleteDatabase: (CDVInvokedUrlCommand*)command;

- (void) compactDatabase: (CDVInvokedUrlCommand*)command;

#pragma mark - Database info

- (void) documentCount: (CDVInvokedUrlCommand*)command;

- (void) lastSequenceNumber: (CDVInvokedUrlCommand*)command;

#pragma mark - Replication

- (void) replicate: (CDVInvokedUrlCommand*)command;

- (void) stopReplication:(CDVInvokedUrlCommand *)command;

#pragma mark - View

- (void) setView: (CDVInvokedUrlCommand*)command;

- (void) setViewFromAssets: (CDVInvokedUrlCommand*)command;

- (void) getFromView: (CDVInvokedUrlCommand*)command;

- (void) stopLiveQuery: (CDVInvokedUrlCommand*)command;

#pragma mark - Changes

- (void) registerWatch: (CDVInvokedUrlCommand*)command;

- (void) removeWatch: (CDVInvokedUrlCommand*)command;

#pragma mark - CRUD

- (void) add: (CDVInvokedUrlCommand*)command;

- (void) get: (CDVInvokedUrlCommand*)command;

- (void) update: (CDVInvokedUrlCommand*)command;

- (void) remove: (CDVInvokedUrlCommand*)command;

- (void) getAll: (CDVInvokedUrlCommand*)command;

@end
