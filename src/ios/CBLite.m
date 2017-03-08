#import "CBLite.h"

#import "CouchbaseLite.h"
#import "CBLRegisterJSViewCompiler.h"

#import <Cordova/CDV.h>

@implementation CBLite

- (void)pluginInitialize {
    dbs = [NSMutableDictionary dictionary]
}
/*
- (void)getURL:(CDVInvokedUrlCommand*)urlCommand
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self.liteURL absoluteString]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:urlCommand.callbackId];
}
*/

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
    option.create = YES;
    option.storageType = kCBLSQLiteStorage;

    NSString* dbName = [command.arguments objectAtIndex:0];

    NSError *error;
    CBLDatabase *database = [[CBLManager sharedInstance] openDatabaseNamed:dbName
                                                               withOptions:option
                                                                     error:&error];

    if (error) {
        NSLog(@"Cannot open database %@ with an error : %@", dbName, [error description]);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error description]];
    } else {
        NSLog(@"Opened database %@", dbName);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        dbs[dbName] = database;
        NSLog(@"Registered database %@", dbs[dbName].name);
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
