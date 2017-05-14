#import "CBLiteLiveQuery.h"

@implementation CBLiteLiveQuery

-(id)init:(CBLQuery *)query withParams:(NSDictionary *)params
{
    if (self = [super init:query withParams:params]) {
        self.live = [query asLiveQuery];
    }
    return self;
}

-(void)runAndNotify:(CBLiteNotify *)note
{
    self.notify = note;
    [self.live addObserver:self forKeyPath:@"rows" options:0 context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSLog(@"LQ: for %@: %@", object, change);
    if ([change count] == 0) {
        return;
    }

    return [self.notify.mgr result:self.notify.command
                          withDict:[self results:self.live.rows]
                           andKeep:YES];
}


-(void)stop
{
    [self.live stop];
}

@end
