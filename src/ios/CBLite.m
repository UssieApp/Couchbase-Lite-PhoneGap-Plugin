#import "CBLite.h"

#import "CouchbaseLite.h"
#import "CBLRegisterJSViewCompiler.h"

#import <Cordova/CDV.h>

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

@implementation CBLite

static NSMutableDictionary<NSString*, CBLiteNotify*> *notifiers;

- (void)pluginInitialize
{
    CBLRegisterJSViewCompiler();
    notifiers = [NSMutableDictionary dictionary];
    self.liveQueries = [NSMutableDictionary dictionary];
}

// Result shorthand

+(CDVPluginResult*)resultFromError:(NSError*)e
{
    return [CDVPluginResult
            resultWithStatus:CDVCommandStatus_ERROR
            messageAsDictionary:@{
                                  @"code": [NSNumber numberWithInteger:e.code],
                                  @"description": e.localizedFailureReason }];
}

+(CDVPluginResult*)resultFromException:(NSException*)e
{
    return [CDVPluginResult
            resultWithStatus:CDVCommandStatus_ERROR
            messageAsDictionary:@{
                                  @"code": @500,
                                  @"description": e.reason }];
}

+(CDVPluginResult*)resultWithCode:(CBLiteResponseCode)code reason:(NSString*)reason
{
    return [CDVPluginResult
            resultWithStatus:CDVCommandStatus_ERROR
            messageAsDictionary:@{
                                  @"code": [NSNumber numberWithInt:code],
                                  @"description": reason }];
}

+(CDVPluginResult*)resultOk
{
    return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
}

+(CDVPluginResult*)resultWithDictionary:(NSDictionary*)dict
{
    return [CDVPluginResult
            resultWithStatus:CDVCommandStatus_OK
            messageAsDictionary:dict];
}

+(CDVPluginResult*)resultWithRevision:(CBLSavedRevision*)rev
{
    return [CDVPluginResult
            resultWithStatus:CDVCommandStatus_OK
            messageAsDictionary:@{ @"_id": [[rev document] documentID],
                                   @"_rev": [rev revisionID] }];
}

+(void)addNotify:(CBLiteNotify*)note
{
    notifiers[note.callbackId] = note;
}

+(void)removeNotify:(NSString*)key
{
    [notifiers removeObjectForKey:key];
}

+(void)removeNotifiersFor:(NSString*)dbName
{
    NSArray* keys = [notifiers allKeys];
    for (NSString* key in keys) {
        CBLiteNotify* note = notifiers[key];
        if (note && note.dbName == dbName) {
            NSLog(@"removing key=%@ for db=%@", key, note.dbName);
            [notifiers removeObjectForKey:key];
        }
    }
}

// helpers

+(NSDictionary*)docFromArguments:(CDVInvokedUrlCommand*)cmd atIndex:(int)index
{

    // check if it's an object
    NSDictionary* data = [cmd argumentAtIndex:index
                                  withDefault:nil
                                     andClass:[NSDictionary class]];

    // if not an object, try parsing into an object from a string
    if (!data) {
        NSString* json = [cmd argumentAtIndex:index
                                  withDefault:nil
                                     andClass:[NSString class]];
        if (json) {
            data = [NSJSONSerialization
                    JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                    options:kNilOptions
                    error:nil];
        }
    }
    return data;
}


// public methods

- (void)info:(CDVInvokedUrlCommand *)command
{
    @try {
        CBLManager* m = [CBLManager sharedInstance];
    
        NSDictionary* out = @{
                              @"version": [NSNumber numberWithInteger:[CBLManager version]],
                              @"directory": [m directory],
                              @"databases": [m allDatabaseNames]
                              };
    
        [self.commandDelegate
         sendPluginResult:[CBLite resultWithDictionary:out]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }
}

- (void)openDatabase:(CDVInvokedUrlCommand*)command
{
    NSString* dbName = [command argumentAtIndex:0];

    BOOL create = [[command argumentAtIndex:1 withDefault:@NO] boolValue];

    @try {
        CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
        option.create = create;
        option.storageType = kCBLSQLiteStorage;

        NSError *error;
        CBLDatabase *db = [[CBLManager sharedInstance] openDatabaseNamed:dbName
                                                             withOptions:option
                                                                   error:&error];

        if (error) {
            NSLog(@"ERROR: %@ [%ld: %@]", error, (long)error.code, error.localizedFailureReason);
            return [self.commandDelegate
                    sendPluginResult:[CBLite resultFromError:error]
                    callbackId:command.callbackId];
        }
        NSLog(@"Opened database %@", [db name]);

        [self.commandDelegate
         sendPluginResult:[CBLite resultOk]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        NSLog(@"EXCEPTION: %@ == %@ (%@)", exception, exception.description, exception.reason);
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }
}

-(void)closeDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSError *error;
            [db close:&error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }
            
            // TODO do we need to remove listeners here?
    
            [self.commandDelegate
             sendPluginResult:[CBLite resultOk]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)deleteDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
        
            NSError *error;
            [db deleteDatabase:&error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }
            
            // TODO do we need to remove listeners here?
    
            [self.commandDelegate
             sendPluginResult:[CBLite resultOk]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)compactDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSError *error;
            [db compact:&error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }
    
            [self.commandDelegate
             sendPluginResult:[CBLite resultOk]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)documentCount:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {

            NSDictionary* out = @{@"count":[NSNumber numberWithUnsignedInteger:[db documentCount]]};
            [self.commandDelegate
             sendPluginResult:[CBLite resultWithDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)lastSequenceNumber:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {

            NSDictionary* out = @{@"last_seq":[NSNumber numberWithLongLong:[db lastSequenceNumber]]};

            [self.commandDelegate
             sendPluginResult:[CBLite resultWithDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

// The NotificationCenter doesn't seem to work when on a background thread!
-(void)replicate:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    NSDictionary* opts = [command argumentAtIndex:1];
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:dbName error:&error];
        if (error) {
            return [self.commandDelegate
                    sendPluginResult:[CBLite resultFromError:error]
                    callbackId:command.callbackId];
        }
        
        NSString* from = opts[@"from"];
        NSString* to = opts[@"to"];
        
        bool continuous = [opts[@"continuous"] boolValue];
        
        CBLReplication* repl;
        if ([from length]) {
            repl = [db createPullReplication:[NSURL URLWithString:from]];
        } else {
            repl = [db createPushReplication:[NSURL URLWithString:to]];
        }
        
        NSDictionary* headers = opts[@"headers"];
        if (headers != NULL) {
            [repl setHeaders:headers];
        }
        
        [repl setContinuous:continuous];
        
        CBLiteNotify* onSync = [[CBLiteNotify alloc]
                                initOnDb:dbName
                                withDelegate:self.commandDelegate
                                forCallbackId:command.callbackId];

        [[NSNotificationCenter defaultCenter] addObserver: onSync
                                                 selector: @selector(onSync:)
                                                     name: kCBLReplicationChangeNotification
                                                   object: repl];
        
        [repl start];
        
        [CBLite addNotify:onSync];
        
        // TODO send first notification containing id
        
    } @catch (NSException* exception) {
        NSLog(@"REPL ERROR: %@", exception);
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }
}

-(void)stopReplication:(CDVInvokedUrlCommand *)command
{
    NSString* id = [command argumentAtIndex:1];
    
    // TODO send a "stopping replication" message?
    
    @try {
        [CBLite removeNotify:id];
        [self.commandDelegate
         sendPluginResult:[CBLite resultOk]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }
    
}

-(void)addView:(CDVInvokedUrlCommand *)command
           map:(NSString*)map
        reduce:(NSString*)reduce
{
    NSString* dbName = [command argumentAtIndex:0];

    NSString* name = [command argumentAtIndex:1];

    NSString* version = [command argumentAtIndex:2];
    
    NSDictionary* opts = [command argumentAtIndex:4];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            CBLView* view = [db viewNamed:name];
            
            NSString* cleanMap = map;
            if (opts) {
                NSDictionary* replace = opts[@"replace"];
                if (replace) {
                    for (NSString* key in replace) {
                        cleanMap = [cleanMap stringByReplacingOccurrencesOfString:key
                                                                       withString:replace[key]];
                    }
                }
                
                view.documentType = opts[@"type"];
            }
            
            id c = [CBLView compiler];
            if (reduce) {
                [view setMapBlock:[c compileMapFunction:cleanMap language:@"javascript"]
                      reduceBlock:[c compileReduceFunction:reduce language:@"javascript"]
                          version:version];
            } else {
                [view setMapBlock:[c compileMapFunction:map language:@"javascript"]
                          version:version];
            }
            
            [self.commandDelegate
             sendPluginResult:[CBLite resultOk]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)setView:(CDVInvokedUrlCommand *)command
{
    NSDictionary* data = [command argumentAtIndex:3];
    
    [self addView:command map:data[@"map"] reduce:data[@"reduce"]];
}

-(void)setViewFromAssets:(CDVInvokedUrlCommand *)command
{
    NSString* viewName = [command argumentAtIndex:1];
    
    NSString* path = [command argumentAtIndex:3];
    
    NSString* root = [self.commandDelegate pathForResource:path];
    
    NSString* mapPath = [NSString stringWithFormat:@"%@/%@/map.js",
                         root, viewName];
    NSString* reducePath = [NSString stringWithFormat:@"%@/%@/reduce.js",
                            root, viewName];

    @try {
        NSFileManager* fMgr = [[NSFileManager alloc] init];
        NSString* map = [[NSString alloc] initWithData:[fMgr contentsAtPath:mapPath]
                                              encoding:NSUTF8StringEncoding];
        
        NSString* reduce;
        if ([fMgr fileExistsAtPath:reducePath]) {
            reduce = [[NSString alloc] initWithData:[fMgr contentsAtPath:reducePath]
                                           encoding:NSUTF8StringEncoding];
        }

        [self addView:command map:map reduce:reduce];
        
    } @catch (NSException* exception) {
        NSLog(@"%@", [exception callStackSymbols]);
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }
}

-(void)getFromView:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    NSString* viewName = [command argumentAtIndex:1];

    NSDictionary* options = [command argumentAtIndex:2];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {

        @try {
            CBLView* v = [db existingViewNamed:viewName];
            if (v == NULL) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultWithCode:cblNotFound reason:@"view_not_found"]
                        callbackId:command.callbackId];
            }

            CBLiteQuery* q = [[CBLiteQuery alloc]
                              init:[v createQuery]
                              withParams:options];

            if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultWithCode:cblBadRequest reason:@"reduce_not_defined"]
                        callbackId:command.callbackId];
            }

            NSError* error;
            NSDictionary* out = [q run:error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }

            [self.commandDelegate
             sendPluginResult:[CBLite resultWithDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)liveQuery:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    NSString* viewName = [command argumentAtIndex:1];
    
    NSDictionary* options = [command argumentAtIndex:2];

    NSError* error;
    CBLDatabase *db = [[CBLManager sharedInstance]
                       databaseNamed:dbName error:&error];
    if (error) {
        return [self.commandDelegate
                sendPluginResult:[CBLite resultFromError:error]
                callbackId:command.callbackId];
    }
    
    CBLView* v = [db existingViewNamed:viewName];
    if (v == NULL) {
        return [self.commandDelegate
                sendPluginResult:[CBLite resultWithCode:cblNotFound reason:@"view_not_found"]
                callbackId:command.callbackId];
    }
    
    CBLiteLiveQuery* q = [[CBLiteLiveQuery alloc]
                          init:[v createQuery]
                          withParams:options];
    
    if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
        return [self.commandDelegate
                sendPluginResult:[CBLite resultWithCode:cblBadRequest reason:@"reduce_not_defined"]
                callbackId:command.callbackId];
    }

    CBLiteNotify* onLive = [[CBLiteNotify alloc]
                            initOnDb:dbName
                            withDelegate:self.commandDelegate
                            forCallbackId:command.callbackId];
    
    [onLive send:@{ @"query_id" : command.callbackId } andKeep:YES];
    
    self.liveQueries[command.callbackId] = q;

    [q runAndNotify:onLive];
}

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command
{
//    NSString* dbName = [command argumentAtIndex:0];

    NSString* key = [command argumentAtIndex:1];

    [self.liveQueries[key] stop];

    [self.liveQueries removeObjectForKey:key];

    [self.commandDelegate
     sendPluginResult:[CBLite resultOk]
     callbackId:command.callbackId];
}

-(void)registerWatch:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:dbName error:&error];
        if (error) {
            return [self.commandDelegate
                    sendPluginResult:[CBLite resultFromError:error]
                    callbackId:command.callbackId];
        }

        CBLiteNotify* onChange = [[CBLiteNotify alloc]
                                  initOnDb:dbName
                                  withDelegate:self.commandDelegate
                                  forCallbackId:command.callbackId];

        [onChange send:@{ @"watch_id" : command.callbackId } andKeep:YES];

        [[NSNotificationCenter defaultCenter] addObserver: onChange
                                                 selector: @selector(onChange:)
                                                     name: kCBLDatabaseChangeNotification
                                                   object: db];

        [CBLite addNotify:onChange];

    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }

}

-(void)removeWatch:(CDVInvokedUrlCommand *)command
{
    NSString* id = [command argumentAtIndex:1];

    // TODO send a "closing watch" message?

    @try {
        [CBLite removeNotify:id];
        [self.commandDelegate
         sendPluginResult:[CBLite resultOk]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }

}

-(void)add:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:1];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }

    // if no data, return an error
    if (!data) {
        // FIXME utilize resultFrom logic for consistency
        return [self.commandDelegate
                sendPluginResult:[CBLite resultWithCode:cblBadRequest reason:@"data_missing"]
                callbackId:command.callbackId];
    }

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError* error;

            NSString* _id = data[@"_id"];

            CBLDocument* doc;
            if (_id) {
                doc = [db documentWithID:_id];
            } else {
                doc = [db createDocument];
            }

            CBLSavedRevision* rev = [doc putProperties:data error:&error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }

            [self.commandDelegate
             sendPluginResult:[CBLite resultWithRevision:rev]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

-(void)get:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    NSString* _id = [command argumentAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
        
            CBLDocument* doc = [db existingDocumentWithID:_id];
        
            [self.commandDelegate
             sendPluginResult:[CBLite resultWithDictionary:[doc properties]]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
   }];
}

-(void)update:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:1];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CBLite resultFromException:exception]
         callbackId:command.callbackId];
    }

    // if no data, return an error
    if (!data) {
        // FIXME utilize resultFrom logic for consistency
        return [self.commandDelegate
                sendPluginResult:[CBLite resultWithCode:cblBadRequest reason:@"data_missing"]
                callbackId:command.callbackId];
    }

    NSString* _id = data[@"_id"];
    if (!_id) {
        return [self.commandDelegate
                sendPluginResult:[CBLite resultWithCode:cblBadRequest reason:@"id_required"]
                callbackId:command.callbackId];
    }

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError* error;
            CBLDocument* doc = [db existingDocumentWithID:_id];
            if (!doc) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultWithCode:cblNotFound reason:@"doc_not_found"]
                        callbackId:command.callbackId];
            }

            CBLSavedRevision* rev = [doc putProperties:data error:&error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }

            [self.commandDelegate
            sendPluginResult:[CBLite resultWithRevision:rev]
            callbackId:command.callbackId];
            } @catch (NSException* exception) {
            [self.commandDelegate
            sendPluginResult:[CBLite resultFromException:exception]
            callbackId:command.callbackId];
            }
    }];
}

-(void)remove:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    NSString* _id = [command argumentAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {

            CBLDocument* doc = [db existingDocumentWithID:_id];

            if (doc) {
                NSError* error;
                [doc deleteDocument:&error];
                if (error) {
                    return [self.commandDelegate
                            sendPluginResult:[CBLite resultFromError:error]
                            callbackId:command.callbackId];
                }
            }

            return [self.commandDelegate
                    sendPluginResult:[CBLite resultOk]
                    callbackId:command.callbackId];
        } @catch (NSException* exception) {
            return [self.commandDelegate
                    sendPluginResult:[CBLite resultFromException:exception]
                    callbackId:command.callbackId];
        }
  }];
}

-(void)getAll:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    NSDictionary* options = [command argumentAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            CBLiteQuery* q = [[CBLiteQuery alloc]
                              init:[db createAllDocumentsQuery]
                              withParams:options];
            
            NSError* error;
            NSDictionary* out = [q run:error];
            if (error) {
                return [self.commandDelegate
                        sendPluginResult:[CBLite resultFromError:error]
                        callbackId:command.callbackId];
            }
            
            [self.commandDelegate
             sendPluginResult:[CBLite resultWithDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            NSLog(@"%@", [exception callStackSymbols]);
            [self.commandDelegate
             sendPluginResult:[CBLite resultFromException:exception]
             callbackId:command.callbackId];
        }
    }];
}

@end

@implementation CBLiteQuery

-(void)parseParams:(NSDictionary*)params
{
    // I HATE this! :)
    for (NSString *key in params) {
        if ([key isEqualToString:@"skip"]) {
            self.q.skip = [params[key] intValue];
        } else if ([key isEqualToString:@"limit"]) {
            self.q.limit = [params[key] intValue];
        } else if ([key isEqualToString:@"inclusive_start"]) {
            self.q.inclusiveStart = [params[key] boolValue];
        } else if ([key isEqualToString:@"inclusive_end"]) {
            self.q.inclusiveEnd = [params[key] boolValue];
        } else if ([key isEqualToString:@"group_level"]) {
            self.q.groupLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"descending"]) {
            self.q.descending = [params[key] boolValue];
        } else if ([key isEqualToString:@"prefetch"]) {
            self.q.prefetch = [params[key] boolValue];
        } else if ([key isEqualToString:@"include_deleted"]) {
            self.q.allDocsMode = kCBLIncludeDeleted;
        } else if ([key isEqualToString:@"include_conflicts"]) {
            self.q.allDocsMode = kCBLShowConflicts;
        } else if ([key isEqualToString:@"only_conflicts"]) {
            self.q.allDocsMode = kCBLOnlyConflicts;
        } else if ([key isEqualToString:@"by_sequence"]) {
            self.q.allDocsMode = kCBLBySequence;
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            self.q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"keys"]) {
            self.q.keys = params[key];
        } else if ([key isEqualToString:@"key"]) {
            self.q.keys = @[params[key]];
        } else if ([key isEqualToString:@"prefix"]) {
            NSString* prefix = params[key];
            self.q.startKey = prefix;
            self.q.endKey = prefix;
            self.q.prefixMatchLevel = 1;
        } else if ([key isEqualToString:@"startkey"]) {
            self.q.startKey = params[key];
        } else if ([key isEqualToString:@"startkey_docid"]) {
            self.q.startKeyDocID = params[key];
        } else if ([key isEqualToString:@"endkey"]) {
            self.q.endKey = params[key];
        } else if ([key isEqualToString:@"endkey_docid"]) {
            self.q.endKeyDocID = params[key];
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            self.q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"reduce"]) {
            self.q.mapOnly = [params[key] boolValue];
        } else if ([key isEqualToString:@"update_index"]) {
            NSString* upd = [params[key] uppercaseString];
            if ([upd isEqualToString: @"BEFORE"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexBefore;
            } else if ([upd isEqualToString: @"AFTER"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexAfter;
            } else if ([upd isEqualToString:@"NEVER"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexNever;
            }
        }
    }
}

-(void)parseOptions:(NSDictionary*)params
{
    self.options[@"prefetch"] = @([params[@"prefetch"] boolValue]);
    self.options[@"include_docs"] = @([params[@"include_docs"] boolValue]);
    self.options[@"mapOnly"] = @([params[@"reduce"] boolValue]);
}

-(id)init:(CBLQuery *)query withParams:(NSDictionary*)params
{
    if (self = [super init]) {
        self.q = query;
        
        self.options = [NSMutableDictionary dictionary];
        if (params) {
            [self parseParams:params];
            [self parseOptions:params];
        }
    }
    
    return self;
}

-(NSMutableDictionary*)results:(CBLQueryEnumerator*)results
{
    NSMutableDictionary* out = [NSMutableDictionary dictionary];
    out[@"count"] = @(results.count);
    out[@"_seq"] = @(results.sequenceNumber);
    out[@"stale"] = @(results.stale);
    
    NSMutableArray* rows = [NSMutableArray array];
    for (CBLQueryRow* r in results) {
        NSMutableDictionary* row = [NSMutableDictionary dictionary];
        
        // FIXME missing values! (compare to Android)
        row[@"_id"] = r.documentID;
        row[@"key"] = r.key;
        row[@"value"] = r.value;
        
        CBLDocument* doc;
        if (self.options[@"prefetch"]) {
            doc = r.document;
        } else if (self.options[@"include_docs"]) {
            NSString* emittedId = [r.value valueForKey:@"_id"];
            doc = [self.q.database documentWithID:emittedId];
        }
        if (doc) {
            row[@"doc"] = doc.properties;
        }
        
        [rows addObject:row];
    }
    
    out[@"rows"] = rows;
    return out;
}

                                                              
-(NSMutableDictionary*)run:(NSError*)error
{
    return [self results:[self.q run:&error]];
}

@end

@implementation CBLiteLiveQuery

-(id)init:(CBLQuery *)query withParams:(NSDictionary *)params
{
    if (self = [super init:query withParams:params]) {
        self.live = [query asLiveQuery];
    }
    return self;
}

-(void)runAndNotify:(CBLiteNotify *)note
{
    self.notify = note;
    [self.live addObserver:self forKeyPath:@"rows" options:0 context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSLog(@"LQ: for %@: %@", object, change);
    if ([change count] == 0) {
        return;
    }
    
    [self.notify send:[self results:self.live.rows] andKeep:YES];
}


-(void)stop
{
    [self.live stop];
}

@end

@implementation CBLiteNotify

-(id)initOnDb:(NSString*)db
 withDelegate:(id<CDVCommandDelegate>)del
forCallbackId:(NSString *)cid
{
    if (self = [super init]) {
        self.dbName = db;
        self.delegate = del;
        self.callbackId = cid;
    }
    return self;
}

-(void)send:(NSDictionary*)out andKeep:(Boolean)keep
{
    CDVPluginResult* res = [CBLite resultWithDictionary:out];
    
    res.keepCallback = [NSNumber numberWithBool:keep];
    
    [self.delegate sendPluginResult:res callbackId:self.callbackId];
    if (!keep) {
        [CBLite removeNotify:self.callbackId];
    }
}

-(void)onChange:(NSNotification *)note
{
    CBLDatabase* db = note.object;
    
    NSNumber* lastSeq = [NSNumber numberWithLongLong:db.lastSequenceNumber];
    
    NSArray* changes = note.userInfo[@"changes"];
    
    NSMutableArray* converted = [NSMutableArray array];
    for (CBLDatabaseChange* change in changes) {
        // FIXME make getting the document too an option
        
        CBLJSONDict* doc = [[CBLJSONDict alloc] init];
        if (change.isCurrentRevision && !change.isDeletion) {
            doc = [[db documentWithID:change.documentID] userProperties];
        }
        NSDictionary* out = @{
                              @"_rev" : change.revisionID,
                              @"_id" : change.documentID,
                              @"current" : [NSNumber numberWithBool: change.isCurrentRevision],
                              @"conflict" : [NSNumber numberWithBool: change.inConflict],
                              @"deletion" : [NSNumber numberWithBool: change.isDeletion],
                              @"doc": doc
                              };
        [converted addObject:out];
    }
    [self send:@{ @"results" : converted, @"last_seq" : lastSeq } andKeep:YES];
}

-(void)onSync:(NSNotification *)note
{
    CBLReplication *r = note.object;
    
    NSMutableDictionary* out = [NSMutableDictionary dictionary];
    
    out[@"replcationId"] = self.callbackId;
    out[@"status"] = [NSNumber numberWithInt:r.status];
    
    if (r.lastError) {
        out[@"lastError"] = r.lastError;
    }
    
    Boolean keep = YES;
    
    switch (r.status) {
        case kCBLReplicationIdle:
            NSLog(@"%@: REPL IDLE: %d of %d [%@] %@ %@",
                  self.callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            break;
        case kCBLReplicationActive:
            NSLog(@"%@: REPL ACTIVE: %d of %d [%@] %@ %@",
                  self.callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            out[@"total"] = [NSNumber numberWithInt:r.changesCount];
            out[@"completed"] = [NSNumber numberWithInt:r.changesCount];
            if (r.pendingDocumentIDs) {
                out[@"pending"] = r.pendingDocumentIDs;
            }
            break;
        case kCBLReplicationOffline:
            NSLog(@"%@: REPL OFFLINE: %d of %d [%@] %@ %@",
                  self.callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            break;
        case kCBLReplicationStopped:
            // TODO remove from registry when done?
            NSLog(@"%@: REPL STOPPED: %d of %d [%@] %@ %@",
                  self.callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            keep = NO;
            break;
    }
    
    [self send:out andKeep:keep];
}

@end
