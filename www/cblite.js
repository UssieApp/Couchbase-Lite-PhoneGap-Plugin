module.exports = {

    res_OK                     : 200,
    res_Created                : 201,
    res_Accepted               : 202,

    res_BadRequest             : 400,
    res_RequiresAuthentication : 401,
    res_Forbidden              : 403,
    res_NotFound               : 404,
    res_Conflict               : 409,

    res_Exception              : 500,
    
    info: function(onSuccess, onError) {
        cordova.exec(onSuccess, onError, "CBLite", "info", []);
    },

    openDatabase: function(onOpenSuccess, onOpenError, name, create) {
        var onOpen = function() {
            return onOpenSuccess({

                name: name,

                closeDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "closeDatabase", [ name ]);
                },

                deleteDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "deleteDatabase", [ name ]);
                },

                compactDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "compact" ]);
                },

                // Database Info

                documentCount: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "documentCount" ]);
                },

                lastSequenceNumber: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "lastSequenceNumber" ]);
                },

                // Replication

                replicate: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "replicate", params ]);
                },

                stopReplicate: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "stopReplicate", id ]);
                },

                // View

                setView: function(onSuccess, onError, viewName, version, data, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "setView", viewName, version, data, options ]);
                },

                setViewFromAssets: function(onSuccess, onError, viewName, version, path, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "setViewFromAssets", viewName, version, path, options ]);
                },

                getFromView: function(onSuccess, onError, viewName, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "getFromView", viewName, params ]);
                },

                getAll: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "getAll", params ]);
                },

                liveQuery: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "liveQuery", id ]);
                },

                stopLiveQuery: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "stopLiveQuery", id ]);
                },

                // Changes

                registerWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "watch", event ]);
                },

                removeWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "stopWatch", event ]);
                },

                // CRUD

                add: function(onSuccess, onError, doc) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "add", doc ]);
                },

                get: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "get", id ]);
                },

                update: function(onSuccess, onError, doc) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "update", doc ]);
                },

                remove: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "onDatabase", [ name, "remove", id ]);
                }

                // putLocalDocument
                // deleteLocalDocument
                // getExistingLocalDocument

                // getView
                // getExistingView

                // setFilter
                // getFilter

                // setValidation
                // getValidation

                // addChangeListener
                // removeChangeListener

                // runAsync
                // runInTransaction

                // setMaxRevTreeDepth

           });
        };
        cordova.exec(onOpen, onOpenError, "CBLite", "openDatabase", [ name, create ]);
    }
};
