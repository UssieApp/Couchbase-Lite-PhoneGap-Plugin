# NOTE

This is an experimental fork, with the intention of building a database-direct cordova build for CBLite, rather than using the Listener. You're probably looking for [the official repository](https://github.com/couchbaselabs/Couchbase-Lite-PhoneGap-Plugin).

If you are still reading, we are open to contributions to this endeavor!

# Cordova plugin for Couchbase Lite

Couchbase Lite is an embedded JSON database for occasionally connected devices. It syncs data in the background, so users can collaborate across devices. There is an event based `_changes` JSON feed API so you can drive data-binding UI frameworks like Sencha and Backbone to reflect remote updates interactively.

It works with native code as well as Cordova / PhoneGap on iOS and Android (you can even sync with Mac desktops), so it doesn't matter where your users are, they can work with the data, and as soon as they get back online, everyone will see their changes.

[Learn more about Couchbase Lite](http://developer.couchbase.com/mobile/).

## How does this differ from the official release?

Couchbase has released a PhoneGap plugin that uses their CBLiteListener to allow queries from Javascript to a local mobile database via HTTPS. It is a fantastic solution for most projects, making it easy to get up and running with CBLite in a WebView app.

It does, however, come at a cost. Performance is less than ideal for heavy query apps, and a lot of the rich features of CBLite are simply not supported.

This is an attempt to expose as much of the native CBLite API directly to Javascript without having to run the listener.

# NOTE

This is a low-priority work in progress for us. As much an experiment as a goal as of yet. You've been forewarned!

Input is welcome!

