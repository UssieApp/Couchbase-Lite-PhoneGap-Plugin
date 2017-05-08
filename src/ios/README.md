All functions take `onSuccess` and `onError` callbacks as the first two parameters, making it easy to wrap in a promise or use directly.

### CBLite.info(...)

Get general information about the CBLite environment. Returns an object.

```
{
    version: <number>,
    directory: <string>,
    databases: [ <string>, ... ]
}
```

### CBLite.openDatabase(..., string name, boolean create_if_missing)

Open a connection to a database. Returns an object with all of the database related methods.

#### db.name

#### db.documentCount(...)

#### db.lastSequenceNumber(...)

#### db.closeDatabase(...)

#### db.deleteDatabase(...)

#### db.compactDatabase(...)

#### db.replicate(..., Object params)
```
params = {
    to: <url>,   // for push replication
    from: <url>  // for pull replication
    headers: {
        Cookie: <string> // session cookie at SyncGateway
    },
    continuous: <boolean>
}
```

#### db.setView(..., string viewName, string version, Object definition, Object options)
This must be called every time the database is opened. Unlike the phonegap plugin, the view definition is NOT stored anywhere in the database. See The official CouchbaseLite Native API for more info.

```
definition = {
    map: function() { ... },
    reduce: function() { ... } // optional
}

options = {
    // see the 
}
