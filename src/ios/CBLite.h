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

@interface CBLiteView : NSObject
{
    
}

@property CBLLiveQuery* query;
    
@property id<CDVCommandDelegate> delegate;
    
@property NSString* callbackId;

@property NSDictionary* options;

#pragma mark - Static Utilities

+(void)add:(NSString*)viewName toDb:(CBLDatabase*)db
                        withVersion:(NSString*)version
                        withOptions:(NSDictionary*)opts
                            withMap:(NSString*)map
                         withReduce:(NSString*)reduce;

+(void)buildQuery:(CBLQuery*)q withParams:(NSDictionary*)params;

+(NSMutableDictionary*)buildResult:(CBLQueryEnumerator*)results
                       withOptions:(NSDictionary*)options
                            fromDb:(CBLDatabase*)db;

#pragma mark - Live Queries

-(id)initWithLiveQuery:(CBLLiveQuery*)q
         forCallbackId:(NSString*)cid
          withDelegate:(id<CDVCommandDelegate>)del
           withOptions:(NSDictionary*)opts;

-(void)stop;

@end

@interface CBLite : CDVPlugin

@property NSMutableDictionary<NSString*, CBLiteView*> *liveQueries;

+(void)addNotify:(CBLiteNotify*)note;

+(void)removeNotify:(NSString*)key;

+(void)removeNotifiersFor:(NSString*)dbName;

#pragma mark - Manager

- (void) info: (CDVInvokedUrlCommand*)command;

- (void) openDatabase: (CDVInvokedUrlCommand*)command;

#pragma mark - Database

- (void) closeDatabase: (CDVInvokedUrlCommand*)command;

- (void) deleteDatabase: (CDVInvokedUrlCommand*)command;

- (void) compactDatabase: (CDVInvokedUrlCommand*)command;


- (void) documentCount: (CDVInvokedUrlCommand*)command;

- (void) lastSequenceNumber: (CDVInvokedUrlCommand*)command;

- (void) replicate: (CDVInvokedUrlCommand*)command;

- (void) stopReplication:(CDVInvokedUrlCommand *)command;

#pragma mark - View

- (void) setView: (CDVInvokedUrlCommand*)command;

- (void) setViewFromAssets: (CDVInvokedUrlCommand*)command;

#pragma mark - Query

- (void) get: (CDVInvokedUrlCommand*)command;

- (void) getAll: (CDVInvokedUrlCommand*)command;

- (void) getFromView: (CDVInvokedUrlCommand*)command;

- (void) stopLiveQuery: (CDVInvokedUrlCommand*)command;

- (void) put: (CDVInvokedUrlCommand*)command;

#pragma mark - Changes

- (void) registerWatch: (CDVInvokedUrlCommand*)command;

- (void) removeWatch: (CDVInvokedUrlCommand*)command;

@end
