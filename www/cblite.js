// TODO keep a map of opened dbs, return the methods as an object with name ready to fill in?

/*

		, ,
		, lastSequenceNumber, ,
		,
		, , ,
		,


*/

module.exports = {
               /*
                returns object with "version", "directory" and "databases"
                */
    info: function(onSuccess, onError) {
        cordova.exec(onSuccess, onError, "CBLite", "info", []);
    },

    openDatabase: function(onOpenSuccess, onOpenError, name, create) {
        var onOpen = function() {
            return onOpenSuccess({
                name: name,
                documentCount: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "documentCount", [ name ]);
                },

                lastSequenceNumber: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "lastSequenceNumber", [ name ]);
                },

                closeDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "closeDatabase", [ name ]);
                },

                deleteDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "deleteDatabase", [ name ]);
                },

                compactDatabase: function(onSuccess, onError) {
                    cordova.exec(onSuccess, onError, "CBLite", "compactDatabase", [ name ]);
                },

            //    allReplications:

                /*
                params:
                {
                    to: "URL",   ??
                    from: "URL", ??
                    session_id: "...",
                    cookie_name: "...",
                    expires: "...",
                    continuous: true
                }
                */
                // currently only supports autl like { session_id: "...", cookie_name: "...", expires: "..." }
                replicate: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "replicate", [ name, params ]);
                },

                // createAllDocumentsQuery
                getAll: function(onSuccess, onError, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "getAll", [ name, params ]);
                },

                setView: function(onSuccess, onError, viewName, version, data, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "setView", [ name, viewName, version, data, options ]);
                },

                setViewFromAssets: function(onSuccess, onError, viewName, version, path, options) {
                    cordova.exec(onSuccess, onError, "CBLite", "setViewFromAssets", [ name, viewName, version, path, options ]);
                },

                get: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "get", [ name, id ]);
                },

                getFromView: function(onSuccess, onError, viewName, params) {
                    cordova.exec(onSuccess, onError, "CBLite", "getFromView", [ name, viewName, params ]);
                },
                                
                                 	
                stopLiveQuery: function(onSuccess, onError, id) {
                    cordova.exec(onSuccess, onError, "CBLite", "stopLiveQuery", [ name, id ]);
                },

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


                put: function(onSuccess, onError, doc) {
                    cordova.exec(onSuccess, onError, "CBLite", "put", [ name, doc ]);
                },

                registerWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "registerWatch", [ name, event ]);
                    document.addEventListener(event, function(data) { console.log(data); }, false);

                },

                removeWatch: function(onSuccess, onError, event) {
                    cordova.exec(onSuccess, onError, "CBLite", "removeWatch", [ name, event ]);
                }

            });
        };
        cordova.exec(onOpen, onOpenError, "CBLite", "openDatabase", [ name, create ]);
    }
};
