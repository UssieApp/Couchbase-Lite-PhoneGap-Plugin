#import "CBLite.h"
#import "CBLiteDatabase.h"

#import "CBLManager.h"
#import "CBLDatabase.h"
#import "CBLRevision.h"
#import "CBLDocument.h"
#import "CBLRegisterJSViewCompiler.h"

static NSMutableDictionary<NSString*, CBLiteDatabase*> *databases;

@implementation CBLite

- (void)pluginInitialize
{
    CBLRegisterJSViewCompiler();
    databases = [NSMutableDictionary dictionary];
}

- (void)info:(CDVInvokedUrlCommand *)command
{
    @try {
        CBLManager* m = [CBLManager sharedInstance];
        
        return [self result:command
                   withDict:@{
                              @"version": @([CBLManager version]),
                              @"directory": [m directory],
                              @"databases": [m allDatabaseNames] }];
    } @catch (NSException* exception) {
        return [self result:command fromException:exception];
    }
}

- (void)openDatabase:(CDVInvokedUrlCommand*)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    BOOL create = [[command argumentAtIndex:1 withDefault:@NO] boolValue];
    
    @try {
        CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
        option.create = create;
        option.storageType = kCBLSQLiteStorage;
        
        NSError *error;
        CBLDatabase *db = [[CBLManager sharedInstance] openDatabaseNamed:dbName
                                                             withOptions:option
                                                                   error:&error];
        if (error) {
            return [self result:command fromError:error];
        }
        
        databases[dbName] = [[CBLiteDatabase alloc] init:dbName withManager:self];
        
        NSLog(@"Opened database %@", [db name]);
        
        return [self resultOk:command];
    } @catch (NSException* exception) {
        return [self result:command fromException:exception];
    }
}

-(void)closeDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    [databases removeObjectForKey:dbName];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            NSError *error;
            [db close:&error];
            if (error) {
                return [self result:command fromError:error];
            }
        
            return [self resultOk:command];
        } @catch (NSException* exception) {
            return [self result:command fromException:exception];
        }
    }];
}

-(void)deleteDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    
    [databases removeObjectForKey:dbName];
    
    [[CBLManager sharedInstance] backgroundTellDatabaseNamed:dbName
                                                          to:^(CBLDatabase* db) {
        @try {
            
            NSError *error;
            [db deleteDatabase:&error];
            if (error) {
                return [self result:command fromError:error];
            }
            
            // TODO do we need to remove listeners here?
            
            return [self resultOk:command];
        } @catch (NSException* exception) {
            return [self result:command fromException:exception];
        }
    }];
}

-(void)onDatabase:(CDVInvokedUrlCommand*)command
            named:(NSString*)name
           action:(NSString*)action
{
    CBLiteDatabase* db = databases[name];
    if (!db) {
        return [self result:command
                   withCode:cblForbidden
                     reason:@"database_not_open"];
    }
    
    SEL selector = NSSelectorFromString([action stringByAppendingString:@":"]);
    
    if (![db respondsToSelector:selector]) {
        return [self result:command
                   withCode:cblBadRequest
                     reason:@"command_unknown"];
    }
    
    NSLog(@"Running command %@ on db %@", action, name);
    
    // Suppresses warning about selector. not sure this is the best solution
    // but seems safe here
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    [db performSelector:selector withObject:command];
    
#pragma clang diagnostic pop
    
}

-(void)onDatabase:(CDVInvokedUrlCommand *)command
{
    NSString* dbName = [command argumentAtIndex:0];
    NSString* action = [command argumentAtIndex:1];
    
    return [self onDatabase:command named:dbName action:action];
    
}

// Result shorthand

-(void)result:(CDVInvokedUrlCommand*)command
    fromError:(NSError*)e
{
     return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_ERROR
                              messageAsDictionary:@{
                                  @"code": [NSNumber numberWithInteger:e.code],
                                  @"description": e.localizedFailureReason }]
            callbackId:command.callbackId];
}

-(void)result:(CDVInvokedUrlCommand*)command
fromException:(NSException*)e
{
    NSLog(@"EXCEPTION: %@", [e callStackSymbols]);
    return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_ERROR
                              messageAsDictionary:@{
                                  @"code": @500,
                                  @"description": e.reason }]
            callbackId:command.callbackId];
}

-(void)resultOk:(CDVInvokedUrlCommand*)command
{
    return [self.commandDelegate
            sendPluginResult:[CDVPluginResult
                              resultWithStatus:CDVCommandStatus_OK]
            callbackId:command.callbackId];
}

-(void)result:(CDVInvokedUrlCommand*)command
     withCode:(CBLiteResponseCode)code
       reason:(NSString*)reason
      andKeep:(BOOL)keep
{
    CDVPluginResult* out = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_ERROR
                            messageAsDictionary:@{
                                @"code": @(code),
                                @"description": reason }];
    out.keepCallback = @(keep);
    return [self.commandDelegate
            sendPluginResult:out
            callbackId:command.callbackId];
}

-(void)result:(CDVInvokedUrlCommand*)command
     withCode:(CBLiteResponseCode)code
       reason:(NSString*)reason
{
    return [self result:command withCode:code reason:reason andKeep:NO];
}

-(void)result:(CDVInvokedUrlCommand*)command
     withDict:(NSDictionary*)dict
      andKeep:(BOOL)keep
{
    CDVPluginResult* out = [CDVPluginResult
                            resultWithStatus:CDVCommandStatus_OK
                            messageAsDictionary:dict];
    out.keepCallback = @(keep);
    return [self.commandDelegate
            sendPluginResult:out
            callbackId:command.callbackId];
}

-(void)result:(CDVInvokedUrlCommand*)command
     withDict:(NSDictionary*)dict
{
    return [self result:command withDict:dict andKeep:NO];
}

-(void)result:(CDVInvokedUrlCommand*)command
 withRevision:(CBLSavedRevision*)rev
      andKeep:(BOOL)keep
{
    return [self result:command
               withDict:@{
                          @"_id": [[rev document] documentID],
                          @"_rev": [rev revisionID] }
                andKeep:keep];
}

-(void)result:(CDVInvokedUrlCommand*)command
 withRevision:(CBLSavedRevision*)rev
{
    return [self result:command withRevision:rev andKeep:NO];
}

// helpers

+(NSDictionary*)docFromArguments:(CDVInvokedUrlCommand*)cmd atIndex:(int)index
{

    // check if it's an object
    NSDictionary* data = [cmd argumentAtIndex:index
                                  withDefault:nil
                                     andClass:[NSDictionary class]];

    // if not an object, try parsing into an object from a string
    if (!data) {
        NSString* json = [cmd argumentAtIndex:index
                                  withDefault:nil
                                     andClass:[NSString class]];
        if (json) {
            data = [NSJSONSerialization
                    JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                    options:kNilOptions
                    error:nil];
        }
    }
    return data;
}

@end

