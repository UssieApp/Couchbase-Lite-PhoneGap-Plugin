#ifndef CORDOVA_CBLITE_DATABASE_NOTIFY_H
#define CORDOVA_CBLITE_DATABASE_NOTIFY_H

#import "CBLiteDatabase.h"
#import "CBLiteNotify.h"

@interface CBLiteDatabase(Notify)

@property NSMutableDictionary<NSString*, CBLiteNotify*> *notifiers;

#pragma mark - Replication

- (void) replicate: (CDVInvokedUrlCommand*)command;

- (void) stopReplicate:(CDVInvokedUrlCommand *)command;

#pragma mark - Changes

- (void) watch: (CDVInvokedUrlCommand*)command;

- (void) stopWatch: (CDVInvokedUrlCommand*)command;

@end

#endif
