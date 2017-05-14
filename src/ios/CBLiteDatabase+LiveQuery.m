#import "CBLiteDatabase+LiveQuery.h"

#import "CBLManager.h"
#import "CBLDatabase.h"


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
        return [self.mgr result:command fromError:error];
    }

    CBLView* v = [db existingViewNamed:viewName];
    if (v == NULL) {
        return [self.mgr result:command
                       withCode:cblNotFound
                         reason:@"view_not_found"];
    }

    CBLiteLiveQuery* q = [[CBLiteLiveQuery alloc]
                          init:[v createQuery]
                          withParams:options];

    if (!q.options[@"mapOnly"] && ![v reduceBlock]) {
        return [self.mgr result:command
                       withCode:cblBadRequest
                         reason:@"reduce_not_defined"];
    }

    CBLiteNotify* onLive = [[CBLiteNotify alloc] initOn:self.mgr
                                         command:command];

    [onLive.mgr result:command
              withDict:@{ @"query_id" : command.callbackId }
               andKeep:YES];

    self.liveQueries[command.callbackId] = q;

    [q runAndNotify:onLive];
}

-(void)stopLiveQuery:(CDVInvokedUrlCommand *)command
{

    NSString* key = [command argumentAtIndex:2];

    [self.liveQueries[key] stop];

    [self.liveQueries removeObjectForKey:key];

    return [self.mgr resultOk:command];
}

@end
