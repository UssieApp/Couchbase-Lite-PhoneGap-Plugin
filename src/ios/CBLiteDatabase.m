#import "CBLiteDatabase.h"
#import "CBLiteQuery.h"

#import "CBLManager.h"
#import "CBLView.h"
#import "CBLDocument.h"
#import "CBLReplication.h"


@implementation CBLiteDatabase

-(id)init:(NSString*)name withManager:(CBLite*)manager
{
    if (self = [super init]) {
        self.name = name;
        self.mgr = manager;
        self.notifiers = [NSMutableDictionary dictionary];
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
                return [self.mgr result:command fromError:error];
            }

            return [self.mgr resultOk:command];

        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
        }
    }];
}

-(void)documentCount:(CDVInvokedUrlCommand *)command
{
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {

            return [self.mgr result:command
                           withDict:@{ @"count": @([db documentCount]) }];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
        }
    }];
}

-(void)lastSequenceNumber:(CDVInvokedUrlCommand *)command
{
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
            return [self.mgr result:command
                           withDict:@{ @"last_seq": @([db lastSequenceNumber]) }];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
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

            return [self.mgr resultOk:command];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
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
        return [self.mgr result:command fromException:exception];
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
                return [self.mgr result:command
                               withCode:cblNotFound
                                 reason:@"view_not_found"];
            }

            CBLiteQuery* q = [[CBLiteQuery alloc]
                              init:[v createQuery]
                              withParams:options];

            if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
                return [self.mgr result:command
                               withCode:cblBadRequest
                                 reason:@"reduce_not_defined"];
            }

            NSError* error;
            NSDictionary* out = [q run:error];
            if (error) {
                return [self.mgr result:command fromError:error];
            }

            return [self.mgr result:command withDict:out];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
        }
    }];
}

-(void)add:(CDVInvokedUrlCommand *)command
{

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:2];
    } @catch (NSException* exception) {
        return [self.mgr result:command fromException:exception];
    }

    // if no data, return an error
    if (!data) {
        return [self.mgr result:command
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
                return [self.mgr result:command fromError:error];
            }

            return [self.mgr result:command withRevision:rev];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
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

            return [self.mgr result:command
                           withDict:[doc properties]];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
        }
   }];
}

-(void)update:(CDVInvokedUrlCommand *)command
{

    NSDictionary* data;
    @try {
        data = [CBLite docFromArguments:command atIndex:2];
    } @catch (NSException* exception) {
        return [self.mgr result:command fromException:exception];
    }

    // if no data, return an error
    if (!data) {
        // FIXME utilize resultFrom logic for consistency
        return [self.mgr result:command
                       withCode:cblBadRequest
                         reason:@"data_missing"];
    }

    NSString* _id = data[@"_id"];
    if (!_id) {
        return [self.mgr result:command
                       withCode:cblBadRequest
                         reason:@"id_required"];
    }

    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:self.name
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError* error;
            CBLDocument* doc = [db existingDocumentWithID:_id];
            if (!doc) {
                return [self.mgr result:command
                               withCode:cblNotFound
                                 reason:@"doc_not_found"];
            }

            CBLSavedRevision* rev = [doc putProperties:data error:&error];
            if (error) {
                return [self.mgr result:command fromError:error];
            }

            return [self.mgr result:command withRevision:rev];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
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
                    return [self.mgr result:command fromError:error];
                }
            }

            return [self.mgr resultOk:command];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
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
                return [self.mgr result:command fromError:error];
            }

            return [self.mgr result:command withDict:out];
        } @catch (NSException* exception) {
            return [self.mgr result:command fromException:exception];
        }
    }];
}

// events

// The NotificationCenter doesn't seem to work when on a background thread!
-(void)replicate:(CDVInvokedUrlCommand *)command
{
    NSDictionary* opts = [command argumentAtIndex:2];
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:self.name
                                                               error:&error];
        if (error) {
            return [self.mgr result:command fromError:error];
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
        
        CBLiteNotify* onSync = [[CBLiteNotify alloc] initOn:self.mgr
                                                    command:command];
        
        [[NSNotificationCenter defaultCenter] addObserver: onSync
                                                 selector: @selector(onSync:)
                                                     name: kCBLReplicationChangeNotification
                                                   object: repl];
        
        [repl start];
        
        self.notifiers[command.callbackId] = onSync;
        
        // TODO send first notification containing id
        
    } @catch (NSException* exception) {
        return [self.mgr result:command fromException:exception];
    }
}

-(void)stopReplicate:(CDVInvokedUrlCommand *)command
{
    NSString* key = [command argumentAtIndex:2];
    
    // TODO send a "stopping replication" message?
    
    @try {
        [self.notifiers removeObjectForKey:key];
        return [self.mgr resultOk:command];
    } @catch (NSException* exception) {
        return [self.mgr result:command fromException:exception];
    }
    
}

-(void)watch:(CDVInvokedUrlCommand *)command
{
    
    @try {
        NSError* error;
        CBLDatabase *db = [[CBLManager sharedInstance] databaseNamed:self.name error:&error];
        if (error) {
            return [self.mgr result:command fromError:error];
        }
        
        CBLiteNotify* onChange = [[CBLiteNotify alloc] initOn:self.mgr
                                                      command:command];
        
        [onChange.mgr result:onChange.command
                      withDict:@{ @"watch_id" : command.callbackId }
                     andKeep:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver: onChange
                                                 selector: @selector(onChange:)
                                                     name: kCBLDatabaseChangeNotification
                                                   object: db];
        
        self.notifiers[command.callbackId] = onChange;
        
    } @catch (NSException* exception) {
        return [self.mgr result:command fromException:exception];
    }
    
}

-(void)stopWatch:(CDVInvokedUrlCommand *)command
{
    NSString* key = [command argumentAtIndex:2];
    
    [self.notifiers removeObjectForKey:key];
    return [self.mgr resultOk:command];
}

@end
