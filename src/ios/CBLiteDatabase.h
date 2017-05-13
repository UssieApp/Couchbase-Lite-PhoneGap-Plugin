#ifndef CORDOVA_CBLITE_DATABASE_H
#define CORDOVA_CBLITE_DATABASE_H

#import "CBLite.h"

@interface CBLiteDatabase : NSObject {

}

@property NSString* name;

@property CBLite* mgr;

- (id) init:(NSString*)name withManager:(CBLite*)manager;

- (void) compact: (CDVInvokedUrlCommand*)command;

#pragma mark - Database info

- (void) documentCount: (CDVInvokedUrlCommand*)command;

- (void) lastSequenceNumber: (CDVInvokedUrlCommand*)command;

#pragma mark - View

- (void) setView: (CDVInvokedUrlCommand*)command;

- (void) setViewFromAssets: (CDVInvokedUrlCommand*)command;

- (void) getFromView: (CDVInvokedUrlCommand*)command;

- (void) getAll: (CDVInvokedUrlCommand*)command;

#pragma mark - CRUD

- (void) add: (CDVInvokedUrlCommand*)command;

- (void) get: (CDVInvokedUrlCommand*)command;

- (void) update: (CDVInvokedUrlCommand*)command;

- (void) remove: (CDVInvokedUrlCommand*)command;

@end

#endif
