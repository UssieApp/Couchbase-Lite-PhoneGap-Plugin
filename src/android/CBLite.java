package com.couchbase.cblite.phonegap;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.LOG;

import com.couchbase.lite.Predicate;
import com.rjfun.cordova.ext.CordovaPluginExt;

import com.couchbase.lite.DocumentChange;
import com.couchbase.lite.Status;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Document;
import com.couchbase.lite.Mapper;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryEnumerator;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.Reducer;
import com.couchbase.lite.SavedRevision;
import com.couchbase.lite.ViewCompiler;
import com.couchbase.lite.android.AndroidContext;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseOptions;
import com.couchbase.lite.Manager;
import com.couchbase.lite.View;

import com.couchbase.lite.javascript.JavaScriptReplicationFilterCompiler;
import com.couchbase.lite.javascript.JavaScriptViewCompiler;

//import com.couchbase.lite.android.AndroidNetworkReachabilityManager;

import com.couchbase.lite.replicator.Replication;
import com.couchbase.lite.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.InputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;

public class CBLite extends CordovaPluginExt {

    private static Manager manager;
    private Map<String, Database> dbs;
    private Map<String, Database.ChangeListener> watches;

    private static DateFormat dateParser = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.ROOT);

    private enum PublicAction {
        info,
        openDatabase, closeDatabase, deleteDatabase,
        documentCount, lastSequenceNumber, compactDatabase,
        replicate,
        getAll, get, put,
        setView,
        setViewFromAssets,
        getFromView,
        registerWatch, removeWatch
    }

    /**
     * Constructor.
     */
    public CBLite() {
        super();
        LOG.i("CBLite()", "constructor called.");
    }

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        LOG.i("initialize", "initialize() called");

        super.initialize(cordova, webView);

        dbs = new ConcurrentHashMap<String, Database>();
        watches = new ConcurrentHashMap<String, Database.ChangeListener>();

        try {
            AndroidContext android = new AndroidContext(this.cordova.getActivity());
/* TODO take advantage of this!
            AndroidNetworkReachabilityManager m = new AndroidNetworkReachabilityManager(android);
*/
            // TODO support native compilers
            View.setCompiler(new JavaScriptViewCompiler());

			Database.setFilterCompiler(new JavaScriptReplicationFilterCompiler());

            // TODO support logging control?
            Manager.enableLogging(Log.TAG, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_SYNC, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_QUERY, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_VIEW, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_CHANGE_TRACKER, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_BLOB_STORE, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_DATABASE, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_MULTI_STREAM_WRITER, Log.VERBOSE);
            Manager.enableLogging(Log.TAG_REMOTE_REQUEST, Log.VERBOSE);

            manager = new Manager(android, Manager.DEFAULT_OPTIONS);
        } catch (final Exception e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }

    @Override
    public void onResume(boolean multitasking) {
        LOG.d("onResume", "CBLite.onResume() called");
    }

    @Override
    public void onPause(boolean multitasking) {
        LOG.d("onPause", "CBLite.onPause() called");
    }

    @Override
    public boolean execute(final String action, final JSONArray args, final CallbackContext callback) {

        if (manager == null) {
            LOG.e("execute", "Failed to initialize couchbase lite.  See console logs");
            return false;
        }

        PublicAction act;
        try {
            act = PublicAction.valueOf(action);
        } catch (IllegalArgumentException e) {
            // not a valid action
            LOG.e("execute", "Unknown action: " + action);
            return false;
        }

        final PublicAction actor = act;

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                // for debugging
                try {
                    String pretty = "[ ]";
                    if (args.length() > 0) {
                        pretty = args.toString(4);
                    }
                    LOG.d("execute", String.format(Locale.US, "CBLite: %s (%d): request = %s", action, actor.ordinal(), pretty));
                    fireEvent("CBLite", action, "request", args);
                } catch (JSONException e) {
                    //
                }

                Object results = null;
                complete:
                try {
                    // Manager methods
                    switch (actor) {
                        case info:
                            results = action_info();
                            break complete;
                    }

                    // Database setup and break down methods
                    final String name = args.getString(0);

                    switch (actor) {
                        case openDatabase:
                            results = action_openDatabase(name, args.getBoolean(1));
                            break complete;
                        case closeDatabase:
                            results = action_closeDatabase(name);
                            break complete;
                        case deleteDatabase:
                            results = action_deleteDatabase(name);
                            break complete;
                    }

                    // actions against the db
                    Database db = dbs.get(name);

                    switch (actor) {
                        case documentCount:
                            results = action_documentCount(db);
                            break complete;
                        case lastSequenceNumber:
                            results = action_lastSequenceNumber(db);
                            break complete;
                        case compactDatabase:
                            results = action_compactDatabase(db);
                            break complete;
                        case replicate:
                            results = action_replicate(db, args.getJSONObject(1));
                            break complete;
                        case getAll:
                            results = action_getAll(db, args.getJSONObject(1));
                            break complete;
                        case get:
                            results = action_get(db, args.getString(1));
                            break complete;
                        case put:
                            results = action_put(db, args.getJSONObject(1));
                            break complete;
                        case setView:
                            results = action_setView(db,
                                    args.getString(1),
                                    args.getString(2),
                                    args.getJSONObject(3),
                                    args.optJSONObject(4));
                            break complete;
                        case setViewFromAssets:
                            results = action_setViewFromAssets(db,
                                    args.getString(1),
                                    args.getString(2),
                                    args.getString(3),
                                    args.optJSONObject(4));
                            break complete;
                        case getFromView:
                            results = action_getFromView(db,
                                    args.getString(1),
                                    args.optJSONObject(2));
                            break complete;
                        case registerWatch:
                            results = action_registerWatch(db, args.getString(1), callback);
                            break complete;
                        case removeWatch:
                            results = action_removeWatch(db, args.getString(1));
                            break complete;
                        default:
                    }

                } catch (final Exception e) {
                    e.printStackTrace();
                    LOG.e("execute", e.getMessage());
                    callback.error(e.getMessage());
                    return;
                }
                if (results instanceof Status) {
                    callback.success(results.toString());
                } else {
                    callback.success((JSONObject) results);
                }

                // for debugging
                String pretty = "";
                try {
                    if (results instanceof Status) {
                        pretty = results.toString();
                    } else {
                        JSONObject asJ = (JSONObject)results;
                        if (asJ != null) {
                            pretty = asJ.toString(4);
                        }
                    }
                } catch (Exception e) {
                    //
                } finally {
                    LOG.d("execute", String.format(Locale.US, "CBLite: %s (%d): results = %s", action, actor.ordinal(), pretty));
                    fireEvent("CBLite", action, "response", args, results);
                }
            }
        });
        return true;
    }

    // methods
    private JSONObject action_info()
            throws JSONException {
        JSONObject out = new JSONObject();
        out.put("version", Manager.VERSION);
        out.put("directory", manager.getDirectory());
        out.put("databases", new JSONArray(manager.getAllDatabaseNames()));
        return out;
    }

    private Status action_openDatabase(String name, boolean create)
            throws CouchbaseLiteException {
        DatabaseOptions options = new DatabaseOptions();
        options.setStorageType("SQLite");
        options.setCreate(create);

        Database database = manager.openDatabase(name, options);
        dbs.put(name, database);
        return new Status(Status.OK);
    }

    private Status action_closeDatabase(String name) {
        Database db = dbs.remove(name);
        db.close();
        return new Status(Status.OK);
    }

    private Status action_deleteDatabase(String name)
            throws CouchbaseLiteException {
        Database db = dbs.remove(name);
        db.delete();
        return new Status(Status.OK);
    }

    private JSONObject action_documentCount(Database db)
            throws JSONException {
        JSONObject out = new JSONObject();
        out.put("count", db.getDocumentCount());
        return out;
    }

    private JSONObject action_lastSequenceNumber(Database db)
            throws JSONException {
        JSONObject out = new JSONObject();
        out.put("last_seq", db.getLastSequenceNumber());
        return out;
    }

    private Status action_compactDatabase(Database db)
            throws CouchbaseLiteException {
        db.compact();
        return new Status(Status.OK);
    }

    private Status action_replicate(Database db, JSONObject data)
            throws JSONException, ParseException, MalformedURLException {
        String from = data.optString("from");
        String to = data.optString("to");

        Replication repl;
        if (!from.isEmpty()) {
            repl = db.createPullReplication(new URL(from));
        } else {
            repl = db.createPushReplication(new URL(to));
        }

        if (!data.isNull("session_id")) {
            String cookie = data.getString("cookie_name");
            String id = data.getString("session_id");

            Date date = dateParser.parse(data.optString("expires"));

            repl.setCookie(cookie, id, "/", date, false, false);
        }

        if (!data.isNull("headers")) {
            repl.setHeaders(toMap(data.getJSONObject("headers")));
        }
        repl.setContinuous(data.optBoolean("continuous", false));

        repl.start();
        return new Status(Status.OK);
    }

    private static List<Object> toList(JSONArray j)
            throws JSONException {
        List<Object> out = new ArrayList<Object>();
        for (int i = 0; i < j.length(); i++) {
            out.add(j.get(i));
        }
        return out;
    }

    private static Map<String, Object> toMap(JSONObject data) {
        Map<String, Object> properties = new HashMap<String, Object>();
        Iterator<String> it = data.keys();
        while (it.hasNext()) {
            String key = it.next();
            properties.put(key, data.opt(key));
        }

        return properties;
    }

    private static void buildQuery(Query q, JSONObject params)
            throws JSONException {

        if (params == null) {
            return;
        }

        q.setSkip(params.optInt("skip", 0));
        q.setLimit(params.optInt("limit", q.getLimit()));
        q.setInclusiveStart(params.optBoolean("inclusive_start", q.isInclusiveStart()));
        q.setInclusiveEnd(params.optBoolean("inclusive_end", q.isInclusiveEnd()));

        if (!params.isNull("group_level")) {
            q.setGroupLevel(params.getInt("group_level"));
        }
        q.setDescending(params.optBoolean("descending", q.isDescending()));
        q.setPrefetch(params.optBoolean("prefetch", q.shouldPrefetch()));

        if (!params.isNull("include_deleted")) {
            q.setAllDocsMode(Query.AllDocsMode.INCLUDE_DELETED);
        } else if (!params.isNull("include_conflicts")) {
            q.setAllDocsMode(Query.AllDocsMode.SHOW_CONFLICTS);
        } else if (!params.isNull("only_conflicts")) {
            q.setAllDocsMode(Query.AllDocsMode.ONLY_CONFLICTS);
        } else if (!params.isNull("by_sequence")) {
            q.setAllDocsMode(Query.AllDocsMode.BY_SEQUENCE);
        }

        q.setPrefixMatchLevel(params.optInt("prefix_match_level", q.getPrefixMatchLevel()));

        if (!params.isNull("keys")) {
            q.setKeys(toList(params.getJSONArray("keys")));
        } else if (!params.isNull("key")) {
            List<Object> keys = new ArrayList<Object>();
            keys.add(params.get("key"));
            q.setKeys(keys);
        } else if (!params.isNull("prefix")) {
            String prefix = params.optString("prefix");
            q.setStartKey(prefix);
            q.setEndKey(prefix);
            q.setPrefixMatchLevel(1);
        } else {
            Object startkey = params.opt("startkey");
            if (startkey != null) {
                if (startkey instanceof JSONArray) {
                    q.setStartKey(toList((JSONArray) startkey));
                } else {
                    q.setStartKey(startkey);
                }
            } else if (!params.isNull("startkey_docid")) {
                q.setStartKeyDocId(params.getString("startkey_docid"));
            }

            Object endkey = params.opt("endkey");
            if (endkey != null) {
                if (endkey instanceof JSONArray) {
                    q.setEndKey(toList((JSONArray) endkey));
                } else {
                    q.setStartKey(endkey);
                }
            } else if (!params.isNull("endkey_docid")) {
                q.setEndKeyDocId(params.getString("endkey_docid"));
            }
        }
        if (!params.isNull("reduce")) {
            q.setMapOnly(!params.optBoolean("reduce"));
        }

        // before, after, never
        if (!params.isNull("update_index")) {
            String label = params.getString("update_index").toUpperCase();
            q.setIndexUpdateMode(Query.IndexUpdateMode.valueOf(label));
        }
    }

    private void addView(Database db,
                         String name,
                         String version,
                         JSONObject options,
                         String map,
                         String reduce,
                         String type) throws JSONException {

        View v = db.getView(name);
        if (options != null) {
            if (!options.isNull("replace")) {
                map = replaceTokens(map, options.getJSONObject("replace"));
            }
            if (!options.isNull("type")) {
                v.setDocumentType(options.getString("type"));
            }
        }

        if (!version.equals(v.getMapVersion())) {
            ViewCompiler comp = View.getCompiler();
            Mapper m = comp.compileMap(map, type);
            if (!reduce.isEmpty()) {
                Reducer r = comp.compileReduce(reduce, type);
                v.setMapReduce(m, r, version);
            } else {
                v.setMap(m, version);
            }
        }
    }

    private String replaceTokens(String src, JSONObject dict) {
        Iterator<String> keys = dict.keys();
        while (keys.hasNext()) {
            String from = keys.next();
            String to = dict.optString(from);
            src = src.replaceAll(from, to);
        }
        return src;
    }

    // TODO get file from context
    private Status action_setView(Database db,
                                  String name,
                                  String version,
                                  JSONObject data,
                                  JSONObject options)
            throws JSONException {
        String map = data.getString("map");
        String reduce = data.optString("reduce");

        addView(db, name, version, options, map, reduce, "javascript");
        return new Status(Status.OK);
    }

    private String loadFromAssets(String filename)
            throws IOException {

        InputStream is = cordova.getActivity().getAssets().open(filename);
        int size = is.available();
        byte[] buffer = new byte[size];

        int read = 0;
        while (read < size) {
            read += is.read(buffer);
        }
        is.close();
        return new String(buffer, "UTF-8");
    }

    private Status action_setViewFromAssets(Database db,
                                            String name,
                                            String version,
                                            String path,
                                            JSONObject options)
            throws IOException, JSONException {

        String map = loadFromAssets(String.format("%s/%s/map.js", path, name));
        String reduce = "";
        try {
            reduce = loadFromAssets(String.format("%s/%s/reduce.js", path, name));
        } catch (IOException e) {
            // reduce is optional, so allow
        }

        addView(db, name, version, options, map, reduce, "javascript");
        return new Status(Status.OK);
    }

    private static JSONObject buildViewResult(Database db, QueryEnumerator results, JSONObject options)
            throws JSONException {

        JSONObject out = new JSONObject();
        out.put("count", results.getCount());
        out.put("_seq", results.getSequenceNumber());
        out.put("stale", results.isStale());

        JSONArray rows = new JSONArray();
        while (results.hasNext()) {
            QueryRow r = results.next();
            JSONObject row = new JSONObject(r.asJSONDictionary());

            Document d = null;
            if (options.optBoolean("prefetch", false)) {
                d = r.getDocument();
            } else if (options.optBoolean("include_docs", false)) {
                d = db.getDocument(row.getJSONObject("value").getString("_id"));
            }
            if (d != null) {
                row.put("doc", new JSONObject(d.getProperties()));
            }

            rows.put(row);
        }

        out.put("rows", rows);
        return out;
    }

    private JSONObject action_getAll(Database db, JSONObject options)
            throws JSONException, CouchbaseLiteException {
        Query q = db.createAllDocumentsQuery();

        buildQuery(q, options);

        QueryEnumerator results = q.run();

        return buildViewResult(db, results, options);
    }

    private JSONObject action_get(Database db, String _id)
            throws CouchbaseLiteException {
        Document doc = db.getExistingDocument(_id);
        if (doc == null) {
            throw (new CouchbaseLiteException("Document not found.", Status.NOT_FOUND));
        }
        return new JSONObject(doc.getProperties());
    }

    private JSONObject action_getFromView(Database db, String name, JSONObject options)
            throws JSONException, CouchbaseLiteException {
        View v = db.getExistingView(name);
        if (v == null) {
            throw (new CouchbaseLiteException("View not found.", Status.NOT_FOUND));
        }
        Query q = v.createQuery();

        if (!q.isMapOnly() && v.getReduce() == null) {
            throw (new CouchbaseLiteException("Reduce requested but not defined.", Status.NOT_FOUND));
        }

        buildQuery(q, options);

        QueryEnumerator results = q.run();

        JSONObject out = buildViewResult(db, results, options);
        out.put("name", name);
        return out;
    }

    private JSONObject action_put(Database db, JSONObject data)
            throws CouchbaseLiteException, JSONException {
        Document doc;
        String _id = data.optString("_id");
        if (_id.isEmpty()) {
            doc = db.createDocument();
        } else {
//				doc = db.getDocument(_id);
            doc = new Document(db, _id);
            data.remove("_id");
        }
        SavedRevision rev = doc.putProperties(toMap(data));
        JSONObject out = new JSONObject();
        out.put("id", _id);
        out.put("rev", rev.getSequence());
        return out;
    }

    private Status action_registerWatch(final Database db,
                                        final String name,
                                        final CallbackContext callback) {
        Database.ChangeListener l = new Database.ChangeListener() {
            @Override
            public void changed(Database.ChangeEvent changeEvent) {
                LOG.d("registerWatch", "changeEvent triggered!");

                final JSONObject out = new JSONObject();
                try {
                    List<DocumentChange> all = changeEvent.getChanges();
                    out.put("name", name);
                    out.put("count", all.size());

                    Iterator<DocumentChange> i = all.iterator();

                    JSONArray errors = new JSONArray();
                    JSONArray rows = new JSONArray();
                    while (i.hasNext()) {
                        try {
                            DocumentChange change = i.next();
                            JSONObject row = new JSONObject();
                            row.put("_id", change.getDocumentId());
                            row.put("_rev", change.getRevisionId());
                            row.put("_conflict", change.isConflict());
                            row.put("_current", change.isCurrentRevision());
                            row.put("_deleted", change.isDeletion());
                            if (change.isCurrentRevision() && !change.isDeletion()) {
                                Document doc = db.getDocument(change.getDocumentId());
                                row.put("doc", new JSONObject(doc.getProperties()));
                            }
                            rows.put(row);
                        } catch (JSONException e) {
                            errors.put(e.getMessage());
                        }
                    }

                    out.put("errors", errors);
                    out.put("rows", rows);

                    // fire as an event for testing
                    fireEvent(name, out);

                    // also put via success listener
                    callback.success(out);
                } catch (JSONException e) {
                    callback.error(e.getMessage());
                }
            }
        };
        watches.put(name, l);
        db.addChangeListener(l);
        return new Status(Status.OK);
    }

    private Status action_removeWatch(Database db, String name) {
        Database.ChangeListener l = watches.remove(name);
        db.removeChangeListener(l);
        return new Status(Status.OK);
    }

    private void fireEvent(final String eventName, final String data) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                fireEvent("document", eventName, data);
            }
        });
    }

    private void fireEvent(String eventName, JSONObject data) {
        fireEvent(eventName, data.toString());
    }

    private void fireEvent(String eventName, Object... data) {
        JSONArray out = new JSONArray();
        for (Object d : data) {
            out.put(d);
        }
        fireEvent(eventName, out.toString());
    }
}
