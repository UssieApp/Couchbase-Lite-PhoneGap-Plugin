#import "CBLiteDatabase+Notify.h"

#import "CBLManager.h"
#import "CBLDatabase.h"
#import "CBLReplication.h"

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

-(void)stopReplicate:(CDVInvokedUrlCommand *)command
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

-(void)watch:(CDVInvokedUrlCommand *)command
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

-(void)stopWatch:(CDVInvokedUrlCommand *)command
{
    NSString* key = [command argumentAtIndex:2];

    [self.notifiers removeObjectForKey:key];
    return [self.mgr resultOk:command.callbackId];
}

@end

