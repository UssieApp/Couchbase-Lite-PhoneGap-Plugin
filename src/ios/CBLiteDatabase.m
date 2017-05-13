#import "CBLiteDatabase.h"
#import "CBLiteQuery.h"

#import "CBLManager.h"
#import "CBLView.h"
#import "CBLDocument.h"

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
