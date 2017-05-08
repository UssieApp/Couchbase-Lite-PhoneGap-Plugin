#import "CBLite.h"

#import "CouchbaseLite.h"
#import "CBLRegisterJSViewCompiler.h"

#import <Cordova/CDV.h>

@implementation CBLite

static NSMutableDictionary<NSString*, CBLiteNotify*> *notifiers;

- (void)pluginInitialize {
    CBLRegisterJSViewCompiler();
    notifiers = [NSMutableDictionary dictionary];
    self.liveQueries = [NSMutableDictionary dictionary];
}

+(void)addNotify:(CBLiteNotify*)note
{
    notifiers[note.callbackId] = note;
}

+(void)removeNotify:(NSString*)id
{
    [notifiers removeObjectForKey:id];
}

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
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_OK
                           messageAsDictionary:out]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }
}

- (void)openDatabase:(CDVInvokedUrlCommand*)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];

    @try {
        CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
        option.create = YES;
        option.storageType = kCBLSQLiteStorage;

        NSError *error;
        CBLDatabase *db = [[CBLManager sharedInstance] openDatabaseNamed:dbName
                                                             withOptions:option
                                                                   error:&error];

        if (error) {
            @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                           reason:[error description]
                                         userInfo:nil];
        }
        NSLog(@"Opened database %@", [db name]);

        [self.commandDelegate
         sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }
}

-(void)closeDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSError *error;
            [db close:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
    
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)deleteDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
        
            NSError *error;
            [db deleteDatabase:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
    
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)compactDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSError *error;
            [db compact:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
    
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)documentCount:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
    
            NSDictionary* out = @{@"count":[NSNumber numberWithUnsignedInteger:[db documentCount]]};
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)lastSequenceNumber:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {

            NSDictionary* out = @{@"last_seq":[NSNumber numberWithLongLong:[db lastSequenceNumber]]};
    
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

// The NotificationCenter doesn't seem to work when on a background thread!
-(void)replicate:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSDictionary* opts = [command.arguments objectAtIndex:1];
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:dbName error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                           reason:[error description]
                                         userInfo:nil];
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
                                initWithDelegate:self.commandDelegate
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
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }
}

-(void)stopReplication:(CDVInvokedUrlCommand *)command
{
    NSString* id = [command.arguments objectAtIndex:1];
    
    // TODO send a "stopping replication" message?
    
    @try {
        [CBLite removeNotify:id];
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }
    
}

-(void)setView:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSString* viewName = [command.arguments objectAtIndex:1];
    
    NSString* version = [command.arguments objectAtIndex:2];
    
    NSDictionary* data = [command.arguments objectAtIndex:3];
    
    NSDictionary* opts = [command.arguments objectAtIndex:4];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            [CBLiteView add:viewName
                       toDb:db
                withVersion:version
                withOptions:opts
                    withMap:data[@"map"]
                 withReduce:data[@"reduce"]];

            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)setViewFromAssets:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];

    NSString* viewName = [command.arguments objectAtIndex:1];
    
    NSString* version = [command.arguments objectAtIndex:2];
    
    NSString* path = [command.arguments objectAtIndex:3];
    
    NSDictionary* options = [command.arguments objectAtIndex:4];

    NSString* root = [self.commandDelegate pathForResource:path];
    
    NSString* mapPath = [NSString stringWithFormat:@"%@/%@/map.js",
                         root, viewName];
    NSString* reducePath = [NSString stringWithFormat:@"%@/%@/reduce.js",
                            root, viewName];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSFileManager* fMgr = [[NSFileManager alloc] init];
            NSString* map = [[NSString alloc] initWithData:[fMgr contentsAtPath:mapPath]
                                                  encoding:NSUTF8StringEncoding];
        
            NSString* reduce;
            if ([fMgr fileExistsAtPath:reducePath]) {
                reduce = [[NSString alloc] initWithData:[fMgr contentsAtPath:reducePath]
                                               encoding:NSUTF8StringEncoding];
            }
        
            [CBLiteView add:viewName
                       toDb:db
                withVersion:version
                withOptions:options
                    withMap:map
                 withReduce:reduce];
        
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        
        } @catch (NSException* exception) {
            NSLog(@"%@", [exception callStackSymbols]);
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)get:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSString* _id = [command.arguments objectAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
        
            CBLDocument* doc = [db existingDocumentWithID:_id];
        
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:[doc properties]]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
   }];
}

-(void)getAll:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSDictionary* options = [command.arguments objectAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            CBLQuery* q = [db createAllDocumentsQuery];
            [CBLiteView buildQuery:q withParams:options];
            
            NSError* error;
            CBLQueryEnumerator* results = [q run:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
            
            NSMutableDictionary* out = [CBLiteView buildResult:results
                                                   withOptions:options
                                                        fromDb:db];
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            NSLog(@"%@", [exception callStackSymbols]);
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

// TODO add support for LiveQueries
-(void)getFromView:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];

    NSString* viewName = [command.arguments objectAtIndex:1];
    
    NSDictionary* options = [command.arguments objectAtIndex:2];

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {

        @try {
            /*
            NSError* error;
            CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:dbName error:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
            */
            CBLView* v = [db existingViewNamed:viewName];
            if (v == NULL) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:@"view not found"
                                             userInfo:nil];
            }
    
            CBLQuery* q = [v createQuery];
            [CBLiteView buildQuery:q withParams:options];

            if (![q mapOnly] && [v reduceBlock] == NULL) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:@"reduce requested but not defined"
                                             userInfo:nil];
            }
/*
            if (options[@"live_query"]) {
                NSString* key = [dbName stringByAppendingFormat:@"%@:%@", viewName, options[@"live_query"]];
                
                NSLog(@"XXXXXXXXXXXXXXXXXXXXXXXXXX Registering LiveQuery at %@:%@", key, command.callbackId);
                
                if (self.liveQueries[key]) {
                    @throw [NSException
                            exceptionWithName:@"CBLDatabaseException"
                            reason:@"LiveQuery with that name already exists!"
                            userInfo:[NSDictionary
                                      dictionaryWithObject:[self.liveQueries[key] valueForKey:@"callbackId"]
                                      forKey:@"callbackId"]];
                }
                
                self.liveQueries[key] = [[CBLiteView alloc] initWithLiveQuery:[q asLiveQuery]
                                                                forCallbackId:command.callbackId
                                                                 withDelegate:self.commandDelegate
                                                                  withOptions:options];
                if (self.liveQueries[key] == nil) {
                    [self.liveQueries removeObjectForKey:key];
                    @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                                   reason:@"Could not initialize LiveQuery"
                                                 userInfo:nil];
                }
 */
 //           } else {
                NSError* error;
                CBLQueryEnumerator* results = [q run:&error];
                if (error) {
                    @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                                   reason:[error description]
                                                 userInfo:nil];
                }
    
                NSMutableDictionary* out = [CBLiteView buildResult:results
                                                       withOptions:options
                                                            fromDb:db];
            
                [self.commandDelegate
                 sendPluginResult:[CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsDictionary:out]
                 callbackId:command.callbackId];
//            }
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command
{
//    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSString* key = [command.arguments objectAtIndex:1];
    
    [self.liveQueries[key] stop];
    
    [self.liveQueries removeObjectForKey:key];
    
    [self.commandDelegate
     sendPluginResult:[CDVPluginResult
                       resultWithStatus:CDVCommandStatus_OK]
     callbackId:command.callbackId];
}

-(void)put:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    NSDictionary* data = [command.arguments objectAtIndex:1];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError* error;
            CBLDocument* doc = [db createDocument];
            CBLSavedRevision* rev = [doc putProperties:data error:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                               reason:[error description]
                                             userInfo:nil];
            }
    
            NSDictionary* out = @{
                                  @"_id": [[rev document] documentID],
                                  @"_rev": [rev revisionID]
                                  };
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsDictionary:out]
             callbackId:command.callbackId];
        } @catch (NSException* exception) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult
                               resultWithStatus:CDVCommandStatus_ERROR
                               messageAsString:[exception reason]]
             callbackId:command.callbackId];
        }
    }];
}

-(void)registerWatch:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command.arguments objectAtIndex:0];
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:dbName error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"CBLDatabaseException"
                                           reason:[error description]
                                         userInfo:nil];
        }
        
        CBLiteNotify* onChange = [[CBLiteNotify alloc]
                                  initWithDelegate:self.commandDelegate
                                  forCallbackId:command.callbackId];
        
        [onChange send:@{ @"watch_id" : command.callbackId } andKeep:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver: onChange
                                                 selector: @selector(onChange:)
                                                     name: kCBLDatabaseChangeNotification
                                                   object: db];

        [CBLite addNotify:onChange];
        
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }

}

-(void)removeWatch:(CDVInvokedUrlCommand *)command
{
    NSString* id = [command.arguments objectAtIndex:1];
    
    // TODO send a "closing watch" message?
    
    @try {
        [CBLite removeNotify:id];
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
         callbackId:command.callbackId];
    } @catch (NSException* exception) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:[exception reason]]
         callbackId:command.callbackId];
    }
    
}

@end

@implementation CBLiteView

+(void)add:(NSString*)viewName toDb:(CBLDatabase*)db
                        withVersion:(NSString*)version
                        withOptions:(NSDictionary*)opts
                            withMap:(NSString*)map
                         withReduce:(NSString*)reduce
{
    CBLView* view = [db viewNamed:viewName];
    
    if ([opts isKindOfClass:[NSDictionary class]]) {
        NSDictionary* replace = opts[@"replace"];
        if (replace) {
            for (NSString* key in replace) {
                map = [map stringByReplacingOccurrencesOfString:key
                                                     withString:replace[key]];
            }
        }
        
        view.documentType = opts[@"type"];
    }
    
    id c = [CBLView compiler];
    if (reduce) {
        [view setMapBlock:[c compileMapFunction:map language:@"javascript"]
              reduceBlock:[c compileReduceFunction:reduce language:@"javascript"]
                  version:version];
    } else {
        [view setMapBlock:[c compileMapFunction:map language:@"javascript"]
                  version:version];
    }
}

+(void)buildQuery:(CBLQuery*)q withParams:(NSDictionary*)params
{
    if (params == NULL) {
        return;
    }
    // I HATE this! :)
    for (NSString *key in params) {
        if ([key isEqualToString:@"skip"]) {
            q.skip = [params[key] intValue];
        } else if ([key isEqualToString:@"limit"]) {
            q.limit = [params[key] intValue];
        } else if ([key isEqualToString:@"inclusive_start"]) {
            q.inclusiveStart = [params[key] boolValue];
        } else if ([key isEqualToString:@"inclusive_end"]) {
            q.inclusiveEnd = [params[key] boolValue];
        } else if ([key isEqualToString:@"group_level"]) {
            q.groupLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"descending"]) {
            q.descending = [params[key] boolValue];
        } else if ([key isEqualToString:@"prefetch"]) {
            q.prefetch = [params[key] boolValue];
        } else if ([key isEqualToString:@"include_deleted"]) {
            q.allDocsMode = kCBLIncludeDeleted;
        } else if ([key isEqualToString:@"include_conflicts"]) {
            q.allDocsMode = kCBLShowConflicts;
        } else if ([key isEqualToString:@"only_conflicts"]) {
            q.allDocsMode = kCBLOnlyConflicts;
        } else if ([key isEqualToString:@"by_sequence"]) {
            q.allDocsMode = kCBLBySequence;
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"keys"]) {
            q.keys = params[key];
        } else if ([key isEqualToString:@"key"]) {
            q.keys = @[params[key]];
        } else if ([key isEqualToString:@"prefix"]) {
            NSString* prefix = params[key];
            q.startKey = prefix;
            q.endKey = prefix;
            q.prefixMatchLevel = 1;
        } else if ([key isEqualToString:@"startkey"]) {
            q.startKey = params[key];
        } else if ([key isEqualToString:@"startkey_docid"]) {
            q.startKeyDocID = params[key];
        } else if ([key isEqualToString:@"endkey"]) {
            q.endKey = params[key];
        } else if ([key isEqualToString:@"endkey_docid"]) {
            q.endKeyDocID = params[key];
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"reduce"]) {
            q.mapOnly = [params[key] boolValue];
        } else if ([key isEqualToString:@"update_index"]) {
            NSString* upd = [params[key] uppercaseString];
            if ([upd isEqualToString: @"BEFORE"]) {
                q.indexUpdateMode = kCBLUpdateIndexBefore;
            } else if ([upd isEqualToString: @"AFTER"]) {
                q.indexUpdateMode = kCBLUpdateIndexAfter;
            } else if ([upd isEqualToString:@"NEVER"]) {
                q.indexUpdateMode = kCBLUpdateIndexNever;
            }
        }
    }
}

+(NSMutableDictionary*)buildResult:(CBLQueryEnumerator*)results
                       withOptions:(NSDictionary*)options
                            fromDb:(CBLDatabase*)db
{
    NSMutableDictionary* out = [NSMutableDictionary dictionary];
    out[@"count"] = @([results count]);
    out[@"_seq"] = @([results sequenceNumber]);
    out[@"stale"] = @([results stale]);
    
    NSMutableArray* rows = [NSMutableArray array];
    for (CBLQueryRow* r in results) {
        NSMutableDictionary* row = [NSMutableDictionary dictionary];
        
        // FIXME missing values! (compare to Android)
        row[@"_id"] = [r documentID];
        row[@"key"] = [r key];
        row[@"value"] = [r value];
        
        CBLDocument* d;
        if (options[@"prefetch"]) {
            d = [r document];
        } else if (options[@"include_docs"]) {
            d = [db documentWithID:[[r value] valueForKey:@"_id"]];
        }
        if (d != NULL) {
            row[@"doc"] = [d properties];
        }
        
        [rows addObject:row];
    }
    
    out[@"rows"] = rows;
    return out;
}

-(id)initWithLiveQuery:(CBLLiveQuery*)q
         forCallbackId:(NSString*)cid
          withDelegate:(id<CDVCommandDelegate>)del
           withOptions:(NSDictionary*)opts
{
    if (self = [super init]) {
        self.query = q;
        self.callbackId = cid;
        self.delegate = del;
        self.options = opts;
        
        [self.query addObserver:self forKeyPath:@"rows" options:0 context:NULL];
        return self;
    }
    return nil;
}

-(void)stop
{
    [self.query stop];
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
    
    CDVPluginResult* res = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_OK
                            messageAsDictionary:[CBLiteView
                                                 buildResult:self.query.rows
                                                 withOptions:self.options
                                                 fromDb: [self.query database]]];
    
    [res setKeepCallbackAsBool:true];
    
    [self.delegate sendPluginResult:res callbackId:self.callbackId];
    
}

@end

@implementation CBLiteNotify

-(id)initWithDelegate:(id<CDVCommandDelegate>)del forCallbackId:(NSString *)cid
{
    if (self = [super init]) {
        self.delegate = del;
        self.callbackId = cid;
    }
    return self;
}

-(void)send:(NSDictionary*)out andKeep:(Boolean)keep
{
    CDVPluginResult* res = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_OK
                            messageAsDictionary:out];
    
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
