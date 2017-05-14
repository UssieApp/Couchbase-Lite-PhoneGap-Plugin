#import "CBLiteNotify.h"
#import "CBLiteDatabase.h"

#import "CBLDatabase.h"
#import "CBLDatabaseChange.h"
#import "CBLDocument.h"
#import "CBLReplication.h"

@implementation CBLiteNotify

-(id)initOn:(CBLite*)manager command:(CDVInvokedUrlCommand*)command
{
    if (self = [super init]) {
        self.mgr = manager;
        self.command = command;
    }
    return self;
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

    return [self.mgr result:self.command
                   withDict:@{ @"results": converted, @"last_seq": lastSeq }
                    andKeep:YES];
}

-(void)onSync:(NSNotification *)note
{
    CBLReplication *r = note.object;
    
    NSString* callbackId = self.command.callbackId;

    NSMutableDictionary* out = [NSMutableDictionary dictionary];

    out[@"replication_id"] = callbackId;
    out[@"status"] = [NSNumber numberWithInt:r.status];

    if (r.lastError) {
        out[@"last_error"] = r.lastError;
    }

    switch (r.status) {
        case kCBLReplicationIdle:
            NSLog(@"%@: REPL IDLE: %d of %d [%@] %@ %@",
                  callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            break;
        case kCBLReplicationActive:
            NSLog(@"%@: REPL ACTIVE: %d of %d [%@] %@ %@",
                  callbackId,
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
                  callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            break;
        case kCBLReplicationStopped:
            NSLog(@"%@: REPL STOPPED: %d of %d [%@] %@ %@",
                  callbackId,
                  r.completedChangesCount,
                  r.changesCount,
                  r.pendingDocumentIDs,
                  r.lastError,
                  r);
            
            // call the manager to stop the replication
            return [self.mgr onDatabase:self.command
                                  named:r.localDatabase.name
                                 action:@"stopReplicate"];
    }

    return [self.mgr result:self.command withDict:out andKeep:YES];
}

@end

