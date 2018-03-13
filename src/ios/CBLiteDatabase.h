#ifndef CORDOVA_CBLITE_DATABASE_H
#define CORDOVA_CBLITE_DATABASE_H

#import "CBLite.h"
#import "CBLiteNotify.h"

@interface CBLiteDatabase : NSObject {

}

@property NSString* name;

@property CBLite* mgr;

@property NSMutableDictionary<NSString*, CBLiteNotify*> *notifiers;

- (id) init:(NSString*)name withManager:(CBLite*)manager;

- (void) compact: (CDVInvokedUrlCommand*)command;

#pragma mark - Database info

- (void) documentCount: (CDVInvokedUrlCommand*)command;

- (void) lastSequenceNumber: (CDVInvokedUrlCommand*)command;

#pragma mark - View

- (void) setView: (CDVInvokedUrlCommand*)command;

- (void) setViewFromAssets: (CDVInvokedUrlCommand*)command;

- (void) unsetView: (CDVInvokedUrlCommand*)command;

- (void) getFromView: (CDVInvokedUrlCommand*)command;

- (void) getAll: (CDVInvokedUrlCommand*)command;

#pragma mark - CRUD

- (void) add: (CDVInvokedUrlCommand*)command;

- (void) get: (CDVInvokedUrlCommand*)command;

- (void) update: (CDVInvokedUrlCommand*)command;

- (void) remove: (CDVInvokedUrlCommand*)command;

#pragma mark - Replication

- (void) replicate: (CDVInvokedUrlCommand*)command;

- (void) stopReplicate:(CDVInvokedUrlCommand *)command;

#pragma mark - Changes

- (void) watch: (CDVInvokedUrlCommand*)command;

- (void) stopWatch: (CDVInvokedUrlCommand*)command;

@end

#endif
