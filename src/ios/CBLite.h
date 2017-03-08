#import <Cordova/CDV.h>

@interface CBLite : CDVPlugin
{
@private
    NSMutableDictionary *dbs;
}


//@property (nonatomic, strong) NSURL *liteURL;

//- (void)getURL:(CDVInvokedUrlCommand*)urlCommand;

#pragma mark - Database

- (void) open: (CDVInvokedUrlCommand*)command;
/*
- (void) close: (CDVInvokedUrlCommand*)command;

#pragma mark - Documents

- (void) get: (CDVInvokedUrlCommand*)command;

#pragma mark - View

- (void) info: (CDVInvokedUrlCommand*)command;

#pragma mark - Replication

#pragma mark - Changes
*/
@end

/*
    All methods should expect @NSString name as the first parameter, and attempt to pull the db
    from the *dbs dictionary(, or create the db if it isn't there?)

    required methods:

    database:
    open(name string, create bool) bool, error
    close(name string)

    view:
    info(db string, view string) json, error
    add(db string, view string, code string, update bool) error
    query(db string, view string, params json) json, error

    document:
    create
    get
    update
    (delete?)
    all


*/


