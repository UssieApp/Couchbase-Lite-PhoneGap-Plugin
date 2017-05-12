#import "CBLite.h"

#import "CouchbaseLite.h"
#import "CBLRegisterJSViewCompiler.h"

#import <Cordova/CDV.h>

static NSMutableDictionary<NSString*, CBLiteDatabase*> *databases;

@implementation CBLite

- (void)pluginInitialize
{
    CBLRegisterJSViewCompiler();
    databases = [NSMutableDictionary dictionary];
}

- (void)info:(CDVInvokedUrlCommand *)command
{
    @try {
        CBLManager* m = [CBLManager sharedInstance];
        
        return [self result:command.callbackId
                   withDict:@{
                              @"version": @([CBLManager version]),
                              @"directory": [m directory],
                              @"databases": [m allDatabaseNames] }];
    } @catch (NSException* exception) {
        return [self result:command.callbackId fromException:exception];
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
            return [self result:command.callbackId fromError:error];
        }
        
        databases[dbName] = [[CBLiteDatabase alloc] init:dbName withManager:self];
        
        NSLog(@"Opened database %@", [db name]);
        
        return [self resultOk:command.callbackId];
    } @catch (NSException* exception) {
        return [self result:command.callbackId fromException:exception];
    }
}

-(void)closeDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    [databases removeObjectForKey:dbName];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError *error;
            [db close:&error];
            if (error) {
                return [self result:command.callbackId fromError:error];
            }
        
            return [self resultOk:command.callbackId];
        } @catch (NSException* exception) {
            return [self result:command.callbackId fromException:exception];
        }
    }];
}

-(void)deleteDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    [databases removeObjectForKey:dbName];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            
            NSError *error;
            [db deleteDatabase:&error];
            if (error) {
                return [self result:command.callbackId fromError:error];
            }
            
            // TODO do we need to remove listeners here?
            
            return [self resultOk:command.callbackId];
        } @catch (NSException* exception) {
            return [self result:command.callbackId fromException:exception];
        }
    }];
}

-(void)onDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    CBLiteDatabase* db = databases[dbName];
    if (!db) {
        return [self result:command.callbackId
                   withCode:cblForbidden
                     reason:@"database_not_open"];
    }
    
    NSString* action = [[command argumentAtIndex:1] stringByAppendingString:@":"];
    SEL selector = NSSelectorFromString(action);
    
    if (![db respondsToSelector:selector]) {
        return [self result:command.callbackId
                   withCode:cblBadRequest
                     reason:@"command_unknown"];
    }
    
    NSLog(@"Running command %@ on db %@", action, dbName);

    // Suppresses warning about selector. not sure this is the best solution
    // but seems safe here
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    [db performSelector:selector withObject:command];

#pragma clang diagnostic pop
}

// Result shorthand

-(void)result:(NSString*)callbackId
    fromError:(NSError*)e
{
     return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_ERROR
                              messageAsDictionary:@{
                                  @"code": [NSNumber numberWithInteger:e.code],
                                  @"description": e.localizedFailureReason }]
            callbackId:callbackId];
}

-(void)result:(NSString*)callbackId
fromException:(NSException*)e
{
    return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_ERROR
                              messageAsDictionary:@{
                                  @"code": @500,
                                  @"description": e.reason }]
            callbackId:callbackId];
}

-(void)resultOk:(NSString*)callbackId
{
    return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_OK]
            callbackId:callbackId];
}

-(void)result:(NSString*)callbackId
     withCode:(CBLiteResponseCode)code
       reason:(NSString*)reason
      andKeep:(BOOL)keep
{
    CDVPluginResult* out = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_ERROR
                            messageAsDictionary:@{
                                @"code": @(code),
                                @"description": reason }];
    out.keepCallback = @(keep);
    return [self.commandDelegate
            sendPluginResult:out
            callbackId:callbackId];
}

-(void)result:(NSString*)callbackId
     withCode:(CBLiteResponseCode)code
       reason:(NSString*)reason
{
    return [self result:callbackId withCode:code reason:reason andKeep:NO];
}

-(void)result:(NSString*)callbackId
     withDict:(NSDictionary*)dict
      andKeep:(BOOL)keep
{
    CDVPluginResult* out = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_OK
                            messageAsDictionary:dict];
    out.keepCallback = @(keep);
    return [self.commandDelegate
            sendPluginResult:out
            callbackId:callbackId];
}

-(void)result:(NSString*)callbackId
     withDict:(NSDictionary*)dict
{
    return [self result:callbackId withDict:dict andKeep:NO];
}

-(void)result:(NSString*)callbackId
 withRevision:(CBLSavedRevision*)rev
      andKeep:(BOOL)keep
{
    return [self result:callbackId
               withDict:@{
                          @"_id": [[rev document] documentID],
                          @"_rev": [rev revisionID] }
                andKeep:keep];
}

-(void)result:(NSString*)callbackId
 withRevision:(CBLSavedRevision*)rev
{
    return [self result:callbackId withRevision:rev andKeep:NO];
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

@end

@implementation CBLiteDatabase

-(id)init:(NSString*)name withManager:(CBLite*)manager
{
    if (self = [super init]) {
        self.name = name;
        self.mgr = manager;
    }
    return self;
}

-(void)compact:(CDVInvokedUrlCommand *)command
{
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSError *error;
            [db compact:&error];
            if (error) {
                return [self.mgr result:command.callbackId fromError:error];
            }
            
            return [self.mgr resultOk:command.callbackId];
            
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)documentCount:(CDVInvokedUrlCommand *)command
{
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {

            return [self.mgr result:command.callbackId
                           withDict:@{ @"count": @([db documentCount]) }];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)lastSequenceNumber:(CDVInvokedUrlCommand *)command
{
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
            return [self.mgr result:command.callbackId
                           withDict:@{ @"last_seq": @([db lastSequenceNumber]) }];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}


-(void)addView:(CDVInvokedUrlCommand *)command
           map:(NSString*)map
        reduce:(NSString*)reduce
{
    NSString* name = [command argumentAtIndex:2];

    NSString* version = [command argumentAtIndex:3];
    
    NSDictionary* opts = [command argumentAtIndex:5];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
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
            
            return [self.mgr resultOk:command.callbackId];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)setView:(CDVInvokedUrlCommand *)command
{
    NSDictionary* data = [command argumentAtIndex:4];
    
    [self addView:command map:data[@"map"] reduce:data[@"reduce"]];
}

-(void)setViewFromAssets:(CDVInvokedUrlCommand *)command
{
    NSString* viewName = [command argumentAtIndex:2];
    
    NSString* path = [command argumentAtIndex:4];
    
    NSString* root = [self.mgr.commandDelegate pathForResource:path];
    
    NSString* mapPath = [NSString stringWithFormat:@"%@/%@/map.js",
                         root, viewName];
    NSString* reducePath = [NSString stringWithFormat:@"%@/%@/reduce.js",
                            root, viewName];

    @try {
        NSFileManager* fMgr = [[NSFileManager alloc] init];
        NSString* map = [[NSString alloc]
                         initWithData:[fMgr contentsAtPath:mapPath]
                         encoding:NSUTF8StringEncoding];
        
        NSString* reduce;
        if ([fMgr fileExistsAtPath:reducePath]) {
            reduce = [[NSString alloc]
                      initWithData:[fMgr contentsAtPath:reducePath]
                      encoding:NSUTF8StringEncoding];
        }

        [self addView:command map:map reduce:reduce];
        
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }
}

-(void)getFromView:(CDVInvokedUrlCommand *)command
{
    NSString* viewName = [command argumentAtIndex:2];

    NSDictionary* options = [command argumentAtIndex:3];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {

        @try {
            CBLView* v = [db existingViewNamed:viewName];
            if (v == NULL) {
                return [self.mgr result:command.callbackId
                               withCode:cblNotFound
                                 reason:@"view_not_found"];
            }

            CBLiteQuery* q = [[CBLiteQuery alloc]
                              init:[v createQuery]
                              withParams:options];

            if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
                return [self.mgr result:command.callbackId
                               withCode:cblBadRequest
                                 reason:@"reduce_not_defined"];
            }

            NSError* error;
            NSDictionary* out = [q run:error];
            if (error) {
                return [self.mgr result:command.callbackId fromError:error];
            }

            return [self.mgr result:command.callbackId withDict:out];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)add:(CDVInvokedUrlCommand *)command
{

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:2];
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }

    // if no data, return an error
    if (!data) {
        return [self.mgr result:command.callbackId
                       withCode:cblBadRequest
                         reason:@"data_missing"];
    }

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
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
                return [self.mgr result:command.callbackId fromError:error];
            }

            return [self.mgr result:command.callbackId withRevision:rev];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)get:(CDVInvokedUrlCommand *)command
{
    NSString* _id = [command argumentAtIndex:2];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
        
            CBLDocument* doc = [db existingDocumentWithID:_id];
        
            return [self.mgr result:command.callbackId
                           withDict:[doc properties]];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
   }];
}

-(void)update:(CDVInvokedUrlCommand *)command
{

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:2];
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }

    // if no data, return an error
    if (!data) {
        // FIXME utilize resultFrom logic for consistency
        return [self.mgr result:command.callbackId
                       withCode:cblBadRequest
                         reason:@"data_missing"];
    }

    NSString* _id = data[@"_id"];
    if (!_id) {
        return [self.mgr result:command.callbackId
                       withCode:cblBadRequest
                         reason:@"id_required"];
    }

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError* error;
            CBLDocument* doc = [db existingDocumentWithID:_id];
            if (!doc) {
                return [self.mgr result:command.callbackId
                               withCode:cblNotFound
                                 reason:@"doc_not_found"];
            }

            CBLSavedRevision* rev = [doc putProperties:data error:&error];
            if (error) {
                return [self.mgr result:command.callbackId fromError:error];
            }

            return [self.mgr result:command.callbackId withRevision:rev];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

-(void)remove:(CDVInvokedUrlCommand *)command
{
    
    NSString* _id = [command argumentAtIndex:2];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {

            CBLDocument* doc = [db existingDocumentWithID:_id];

            if (doc) {
                NSError* error;
                [doc deleteDocument:&error];
                if (error) {
                    return [self.mgr result:command.callbackId fromError:error];
                }
            }

            return [self.mgr resultOk:command.callbackId];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
  }];
}

-(void)getAll:(CDVInvokedUrlCommand *)command
{
    
    NSDictionary* options = [command argumentAtIndex:2];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
            CBLiteQuery* q = [[CBLiteQuery alloc]
                              init:[db createAllDocumentsQuery]
                              withParams:options];
            
            NSError* error;
            NSDictionary* out = [q run:error];
            if (error) {
                return [self.mgr result:command.callbackId fromError:error];
            }
            
            return [self.mgr result:command.callbackId withDict:out];
        } @catch (NSException* exception) {
            return [self.mgr result:command.callbackId fromException:exception];
        }
    }];
}

@end

@implementation CBLiteDatabase(Notify)

@dynamic notifiers;

// The NotificationCenter doesn't seem to work when on a background thread!
-(void)replicate:(CDVInvokedUrlCommand *)command
{
    NSDictionary* opts = [command argumentAtIndex:2];
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:self.name
                                                               error:&error];
        if (error) {
            return [self.mgr result:command.callbackId fromError:error];
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
        
        CBLiteNotify* onSync = [[CBLiteNotify alloc] initOn:self
                                              forCallbackId:command.callbackId];
        
        [[NSNotificationCenter defaultCenter] addObserver: onSync
                                                 selector: @selector(onSync:)
                                                     name: kCBLReplicationChangeNotification
                                                   object: repl];
        
        [repl start];
        
        self.notifiers[command.callbackId] = onSync;
        
        // TODO send first notification containing id
        
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }
}

-(void)stopReplication:(CDVInvokedUrlCommand *)command
{
    NSString* key = [command argumentAtIndex:2];
    
    // TODO send a "stopping replication" message?
    
    @try {
        [self.notifiers removeObjectForKey:key];
        return [self.mgr resultOk:command.callbackId];
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }
    
}

-(void)registerWatch:(CDVInvokedUrlCommand *)command
{
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:self.name error:&error];
        if (error) {
            return [self.mgr result:command.callbackId fromError:error];
        }
        
        CBLiteNotify* onChange = [[CBLiteNotify alloc] initOn:self
                                                forCallbackId:command.callbackId];
        
        [onChange send:@{ @"watch_id" : command.callbackId } andKeep:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver: onChange
                                                 selector: @selector(onChange:)
                                                     name: kCBLDatabaseChangeNotification
                                                   object: db];
        
        self.notifiers[command.callbackId] = onChange;
        
    } @catch (NSException* exception) {
        return [self.mgr result:command.callbackId fromException:exception];
    }
    
}

-(void)removeWatch:(CDVInvokedUrlCommand *)command
{
    NSString* key = [command argumentAtIndex:2];
    
    [self.notifiers removeObjectForKey:key];
    return [self.mgr resultOk:command.callbackId];
}


@end

@implementation CBLiteDatabase(LiveQuery)

@dynamic liveQueries;

-(void)liveQuery:(CDVInvokedUrlCommand *)command
{
    NSString* viewName = [command argumentAtIndex:2];
    
    NSDictionary* options = [command argumentAtIndex:3];
    
    NSError* error;
    CBLDatabase *db = [[CBLManager sharedInstance]
                       databaseNamed:self.name error:&error];
    if (error) {
        return [self.mgr result:command.callbackId fromError:error];
    }
    
    CBLView* v = [db existingViewNamed:viewName];
    if (v == NULL) {
        return [self.mgr result:command.callbackId
                       withCode:cblNotFound
                         reason:@"view_not_found"];
    }
    
    CBLiteLiveQuery* q = [[CBLiteLiveQuery alloc]
                          init:[v createQuery]
                          withParams:options];
    
    if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
        return [self.mgr result:command.callbackId
                       withCode:cblBadRequest
                         reason:@"reduce_not_defined"];
    }
    
    CBLiteNotify* onLive = [[CBLiteNotify alloc] initOn:self
                                          forCallbackId:command.callbackId];
    
    [onLive send:@{ @"query_id" : command.callbackId } andKeep:YES];
    
    self.liveQueries[command.callbackId] = q;
    
    [q runAndNotify:onLive];
}

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command
{
    
    NSString* key = [command argumentAtIndex:2];
    
    [self.liveQueries[key] stop];
    
    [self.liveQueries removeObjectForKey:key];
    
    return [self.mgr resultOk:command.callbackId];
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
    
    return [self.notify send:[self results:self.live.rows] andKeep:YES];
}


-(void)stop
{
    [self.live stop];
}

@end

@implementation CBLiteNotify

-(id)initOn:(CBLiteDatabase*)db forCallbackId:(NSString *)callbackId
{
    if (self = [super init]) {
        self.db = db;
        self.callbackId = callbackId;
    }
    return self;
}

-(void)send:(NSDictionary*)out andKeep:(BOOL)keep
{
    if (!keep) {
        // clean me up, I'm done!
        [self.db.notifiers removeObjectForKey:self.callbackId];
    }
    return [self.db.mgr result:self.callbackId withDict:out andKeep:keep];
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
    
    return [self send:@{ @"results": converted, @"last_seq": lastSeq } andKeep:YES];
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
    
    return [self send:out andKeep:keep];
}

@end

