#ifndef CORDOVA_CBLITE_H
#define CORDOVA_CBLITE_H

#import <Cordova/CDV.h>

#import "CBLRevision.h"

// Just in case
typedef NS_ENUM(NSInteger, CBLiteResponseCode) {
    cblOK                     = 200,
    cblCreated                = 201,
    cblAccepted               = 202,
    
    cblBadRequest             = 400,
    cblRequiresAuthentication = 401,
    cblForbidden              = 403,
    cblNotFound               = 404,
    cblConflict               = 409,
    
    cblException              = 500
};

@interface CBLite : CDVPlugin

#pragma mark - Manager

- (void) info: (CDVInvokedUrlCommand*)command;

- (void) onDatabase: (CDVInvokedUrlCommand*)command;

- (void) openDatabase: (CDVInvokedUrlCommand*)command;

- (void) closeDatabase: (CDVInvokedUrlCommand*)command;

- (void) deleteDatabase: (CDVInvokedUrlCommand*)command;

#pragma mark - Replies

-(void)result:(NSString*)callbackId fromError:(NSError*)error;

-(void)result:(NSString*)callbackId fromException:(NSException*)eexception;

-(void)resultOk:(NSString*)callbackId;

-(void)result:(NSString*)callbackId withCode:(CBLiteResponseCode)code reason:(NSString*)reason andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withCode:(CBLiteResponseCode)code reason:(NSString*)reason;

-(void)result:(NSString*)callbackId withDict:(NSDictionary*)dict andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withDict:(NSDictionary*)dict;

-(void)result:(NSString*)callbackId withRevision:(CBLSavedRevision*)rev andKeep:(BOOL)keep;

-(void)result:(NSString*)callbackId withRevision:(CBLSavedRevision*)rev;

#pragma mark - Helpers

+(NSDictionary*)docFromArguments:(CDVInvokedUrlCommand*)cmd atIndex:(int)index;

@end

#endif
