package com.ussieapp.cblite.phonegap;

import android.content.Context;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.json.JSONArray;
import org.json.JSONException;

import com.couchbase.lite.android.AndroidContext;

import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseOptions;
import com.couchbase.lite.Manager;
/*
import com.couchbase.lite.listener.LiteListener;
import com.couchbase.lite.listener.LiteServlet;
import com.couchbase.lite.listener.Credentials;
*/
import com.couchbase.lite.View;

import com.couchbase.lite.javascript.JavaScriptReplicationFilterCompiler;
import com.couchbase.lite.javascript.JavaScriptViewCompiler;
import com.couchbase.lite.util.Log;

import java.util.Map;
import java.util.HashMap;
import java.io.IOException;
// import java.io.File;

public class CBLite extends CordovaPlugin {

	private static Manager manager;
	private Map<String, Database> dbs;

	private boolean initFailed = false;

	/**
	 * Constructor.
	 */
	public CBLite() {
		super();
		System.out.println("CBLite() constructor called");
	}

	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		System.out.println("initialize() called");

		super.initialize(cordova, webView);

		dbs = new HashMap<String, Database>();

		try {
			View.setCompiler(new JavaScriptViewCompiler());
			Database.setFilterCompiler(new JavaScriptReplicationFilterCompiler());

			Manager.enableLogging(Log.TAG, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_SYNC, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_QUERY, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_VIEW, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_CHANGE_TRACKER, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_BLOB_STORE, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_DATABASE, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_MULTI_STREAM_WRITER, Log.VERBOSE);
			Manager.enableLogging(Log.TAG_REMOTE_REQUEST, Log.VERBOSE);
			manager = new Manager(new AndroidContext(this.cordova.getActivity()), Manager.DEFAULT_OPTIONS);
		} catch (final Exception e) {
			e.printStackTrace();
			initFailed = true;
			throw new RuntimeException(e);
		}
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callback) throws JSONException {
		if (initFailed == true) {
			callback.error("Failed to initialize couchbase lite.  See console logs");
			return false;
		}
		try {
			String name = args.getString(0);
			if (action.equals("open")) {
				return this.open(name, callback);
			} else if (action.equals("close")) {
				return this.close(name, callback);
			}
		} catch (final Exception e) {
			e.printStackTrace();
			callback.error(e.getMessage());
		}
		return false;
	}

	public void onResume(boolean multitasking) {
		System.out.println("CBLite.onResume() called");
	}

	public void onPause(boolean multitasking) {
		System.out.println("CBLite.onPause() called");
	}

	private boolean open(String name, CallbackContext callback) throws JSONException {
		try {
			DatabaseOptions options = new DatabaseOptions();
			options.setCreate(true);

			Database database = manager.openDatabase(name, options);
			dbs.put(name, database);
			callback.success();
			return true;
		} catch (final Exception e) {
			initFailed = true;
			callback.error(e.getMessage());
			return false;
		}
	}

	private boolean close(String name, CallbackContext callback) throws JSONException {
		dbs.remove(name);
		callback.success();
		return true;
	}



}
