#import <Cordova/CDV.h>
#import "CBLDatabase.h"
#import "CBLQuery.h"

// Just in case
typedef NS_ENUM(NSInteger, CBLiteResponseCode) {
    cblOK                     = 200,
    cblCreated                = 201,
    cblAccepted               = 202,
    
    cblBadRequest             = 400,
    cblRequiresAuthentication = 401,
    cblForbidden              = 403,
    cblNotFound               = 404,
    
    cblException              = 500
};

@interface CBLite : CDVPlugin

#pragma mark - Manager

- (void) info: (CDVInvokedUrlCommand*)command;

- (void) onDatabase: (CDVInvokedUrlCommand*)command;

- (void) openDatabase: (CDVInvokedUrlCommand*)command;

- (void) closeDatabase: (CDVInvokedUrlCommand*)command;

- (void) deleteDatabase: (CDVInvokedUrlCommand*)command;

#pragma mark - Replies

-(void)result:(NSString*)callbackId fromError:(NSError*)error;

-(void)result:(NSString*)callbackId fromException:(NSException*)eexception;

-(void)resultOk:(NSString*)callbackId;

-(void)result:(NSString*)callbackId withCode:(CBLiteResponseCode)code reason:(NSString*)reason andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withCode:(CBLiteResponseCode)code reason:(NSString*)reason;

-(void)result:(NSString*)callbackId withDict:(NSDictionary*)dict andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withDict:(NSDictionary*)dict;

-(void)result:(NSString*)callbackId withRevision:(CBLSavedRevision*)rev andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withRevision:(CBLSavedRevision*)rev;

#pragma mark - Helpers

+(NSDictionary*)docFromArguments:(CDVInvokedUrlCommand*)cmd atIndex:(int)index;

@end

@interface CBLiteDatabase : NSObject {
    
}

@property NSString* name;

@property CBLite* mgr;

- (id) init:(NSString*)name withManager:(CBLite*)manager;

- (void) compact: (CDVInvokedUrlCommand*)command;

#pragma mark - Database info

- (void) documentCount: (CDVInvokedUrlCommand*)command;

- (void) lastSequenceNumber: (CDVInvokedUrlCommand*)command;

#pragma mark - View

- (void) setView: (CDVInvokedUrlCommand*)command;

- (void) setViewFromAssets: (CDVInvokedUrlCommand*)command;

- (void) getFromView: (CDVInvokedUrlCommand*)command;

- (void) getAll: (CDVInvokedUrlCommand*)command;

#pragma mark - CRUD

- (void) add: (CDVInvokedUrlCommand*)command;

- (void) get: (CDVInvokedUrlCommand*)command;

- (void) update: (CDVInvokedUrlCommand*)command;

- (void) remove: (CDVInvokedUrlCommand*)command;

@end

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

#pragma mark - Require Notifications

@interface CBLiteDatabase(Notify)

@property NSMutableDictionary<NSString*, CBLiteNotify*> *notifiers;

#pragma mark - Replication

- (void) replicate: (CDVInvokedUrlCommand*)command;

- (void) stopReplication:(CDVInvokedUrlCommand *)command;

#pragma mark - Changes

- (void) registerWatch: (CDVInvokedUrlCommand*)command;

- (void) removeWatch: (CDVInvokedUrlCommand*)command;

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

#pragma mark - Live Queries

@interface CBLiteDatabase(LiveQuery)

@property NSMutableDictionary<NSString*, CBLiteLiveQuery*> *liveQueries;

-(void)liveQuery:(CDVInvokedUrlCommand *)command;

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command;


@end
