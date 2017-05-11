module.exports = {
    
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
                    cordova.exec(onSuccess, onError, "CBLite", "compactDatabase", [ name ]);
                },

                // Database Info

                documentCount: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "documentCount", [ name ]);
                },

                lastSequenceNumber: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "lastSequenceNumber", [ name ]);
                },

                // Replication

                replicate: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "replicate", [ name, params ]);
                },

                stopReplicate: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "stopReplicate", [ name, id ]);
                },

                // View

                setView: function(onSuccess, onError, viewName, version, data, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "setView", [ name, viewName, version, data, options ]);
                },

                setViewFromAssets: function(onSuccess, onError, viewName, version, path, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "setViewFromAssets", [ name, viewName, version, path, options ]);
                },

                getFromView: function(onSuccess, onError, viewName, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "getFromView", [ name, viewName, params ]);
                },

                getAll: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "getAll", [ name, params ]);
                },

                liveQuery: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "stopLiveQuery", [ name, id ]);
                },

                stopLiveQuery: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "stopLiveQuery", [ name, id ]);
                },

                // Changes

                registerWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "registerWatch", [ name, event ]);
                },

                removeWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "removeWatch", [ name, event ]);
                },

                // CRUD

                add: function(onSuccess, onError, doc) {
                    cordova.exec(onSuccess, onError, "CBLite", "add", [ name, doc ]);
                },

                get: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "get", [ name, id ]);
                },

                update: function(onSuccess, onError, doc) {
                    cordova.exec(onSuccess, onError, "CBLite", "update", [ name, doc ]);
                },

                remove: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "remove", [ name, id ]);
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
