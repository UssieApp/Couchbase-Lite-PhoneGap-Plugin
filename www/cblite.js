// TODO keep a map of opened dbs, return the methods as an object with name ready to fill in?

module.exports = {
    open: function(name, onSuccess, onError) {
         cordova.exec(onSuccess, onError, "CBLite", "open", [ name ]);
    }
}
