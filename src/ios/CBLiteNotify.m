#import "CBLiteNotify.h"
#import "CBLiteDatabase.h"
#import "CBLiteDatabase+Notify.h"

#import "CBLDatabase.h"
#import "CBLDatabaseChange.h"
#import "CBLDocument.h"
#import "CBLReplication.h"

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

