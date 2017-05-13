#import "CBLiteQuery.h"

#import "CBLDatabase.h"
#import "CBLDocument.h"

@implementation CBLiteQuery

-(void)parseParams:(NSDictionary*)params
{
    // I HATE this! :)
    for (NSString *key in params) {
        if ([key isEqualToString:@"skip"]) {
            self.q.skip = [params[key] intValue];
        } else if ([key isEqualToString:@"limit"]) {
            self.q.limit = [params[key] intValue];
        } else if ([key isEqualToString:@"inclusive_start"]) {
            self.q.inclusiveStart = [params[key] boolValue];
        } else if ([key isEqualToString:@"inclusive_end"]) {
            self.q.inclusiveEnd = [params[key] boolValue];
        } else if ([key isEqualToString:@"group_level"]) {
            self.q.groupLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"descending"]) {
            self.q.descending = [params[key] boolValue];
        } else if ([key isEqualToString:@"prefetch"]) {
            self.q.prefetch = [params[key] boolValue];
        } else if ([key isEqualToString:@"include_deleted"]) {
            self.q.allDocsMode = kCBLIncludeDeleted;
        } else if ([key isEqualToString:@"include_conflicts"]) {
            self.q.allDocsMode = kCBLShowConflicts;
        } else if ([key isEqualToString:@"only_conflicts"]) {
            self.q.allDocsMode = kCBLOnlyConflicts;
        } else if ([key isEqualToString:@"by_sequence"]) {
            self.q.allDocsMode = kCBLBySequence;
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            self.q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"keys"]) {
            self.q.keys = params[key];
        } else if ([key isEqualToString:@"key"]) {
            self.q.keys = @[params[key]];
        } else if ([key isEqualToString:@"prefix"]) {
            NSString* prefix = params[key];
            self.q.startKey = prefix;
            self.q.endKey = prefix;
            self.q.prefixMatchLevel = 1;
        } else if ([key isEqualToString:@"startkey"]) {
            self.q.startKey = params[key];
        } else if ([key isEqualToString:@"startkey_docid"]) {
            self.q.startKeyDocID = params[key];
        } else if ([key isEqualToString:@"endkey"]) {
            self.q.endKey = params[key];
        } else if ([key isEqualToString:@"endkey_docid"]) {
            self.q.endKeyDocID = params[key];
        } else if ([key isEqualToString:@"prefix_match_level"]) {
            self.q.prefixMatchLevel = [params[key] unsignedIntegerValue];
        } else if ([key isEqualToString:@"reduce"]) {
            self.q.mapOnly = [params[key] boolValue];
        } else if ([key isEqualToString:@"update_index"]) {
            NSString* upd = [params[key] uppercaseString];
            if ([upd isEqualToString: @"BEFORE"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexBefore;
            } else if ([upd isEqualToString: @"AFTER"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexAfter;
            } else if ([upd isEqualToString:@"NEVER"]) {
                self.q.indexUpdateMode = kCBLUpdateIndexNever;
            }
        }
    }
}

-(void)parseOptions:(NSDictionary*)params
{
    self.options[@"prefetch"] = @([params[@"prefetch"] boolValue]);
    self.options[@"include_docs"] = @([params[@"include_docs"] boolValue]);
    self.options[@"mapOnly"] = @([params[@"reduce"] boolValue]);
}

-(id)init:(CBLQuery *)query withParams:(NSDictionary*)params
{
    if (self = [super init]) {
        self.q = query;

        self.options = [NSMutableDictionary dictionary];
        if (params) {
            [self parseParams:params];
            [self parseOptions:params];
        }
    }

    return self;
}

-(NSMutableDictionary*)results:(CBLQueryEnumerator*)results
{
    NSMutableDictionary* out = [NSMutableDictionary dictionary];
    out[@"count"] = @(results.count);
    out[@"_seq"] = @(results.sequenceNumber);
    out[@"stale"] = @(results.stale);

    NSMutableArray* rows = [NSMutableArray array];
    for (CBLQueryRow* r in results) {
        NSMutableDictionary* row = [NSMutableDictionary dictionary];

        // FIXME missing values! (compare to Android)
        row[@"_id"] = r.documentID;
        row[@"key"] = r.key;
        row[@"value"] = r.value;

        CBLDocument* doc;
        if (self.options[@"prefetch"]) {
            doc = r.document;
        } else if (self.options[@"include_docs"]) {
            NSString* emittedId = [r.value valueForKey:@"_id"];
            doc = [self.q.database documentWithID:emittedId];
        }
        if (doc) {
            row[@"doc"] = doc.properties;
        }

        [rows addObject:row];
    }

    out[@"rows"] = rows;
    return out;
}


-(NSMutableDictionary*)run:(NSError*)error
{
    return [self results:[self.q run:&error]];
}

@end



