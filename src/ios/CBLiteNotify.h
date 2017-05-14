#ifndef CORDOVA_CBLITE_NOTIFY_H
#define CORDOVA_CBLITE_NOTIFY_H

#import "CBLite.h"

@interface CBLiteNotify : NSObject
{

}

@property CBLite* mgr;

@property CDVInvokedUrlCommand* command;

-(id)initOn:(CBLite*)manager command:(CDVInvokedUrlCommand*)command;

-(void)onChange:(NSNotification*)note;

-(void)onSync:(NSNotification*)note;

@end

#endif
