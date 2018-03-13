exports.defineAutoTests = function() {

  var dbName = 'cb-tests';

  /*

  before:
  create db
  add sync
  add user
  insert test records

  then:
  push sync - once
  pull sync - once

  start push continuous
  start pull continuous

  inject local records
  inject remote records

  stop push
  stop pull

  after:
  delete db

  */

  var testDocs = [
    // docs with keys
    { _id: "1", name: "one",   type: "foo", channels: [ 'all' ] },
    { _id: "2", name: "two",   type: "bar", channels: [ 'all' ] },
    // docs without keys
    {           name: "three", type: "foo", channels: [ 'all' ] },
    {           name: "four",  type: "bar", channels: [ 'all' ] },
    // more random records
    {           name: "five",  type: "foo", channels: [ 'all' ] },
    {           name: "six",   type: "bar", channels: [ 'all' ] },
    {           name: "seven", type: "foo", channels: [ 'all' ] },
    {           name: "eight", type: "bar", channels: [ 'all' ] },
    {           name: "nine",  type: "foo", channels: [ 'all' ] },
    {           name: "ten",   type: "bar", channels: [ 'all' ] }
  ];

  var serverDocs = [
    {           name: "A",     type: "foo", channels: [ 'all' ] },
    {           name: "B",     type: "bar", channels: [ 'all' ] },
    {           name: "C",     type: "foo", channels: [ 'all' ] },
    {           name: "D",     type: "bar", channels: [ 'all' ] },
    {           name: "E",     type: "foo", channels: [ 'all' ] },
    {           name: "F",     type: "bar", channels: [ 'all' ] }
  ];

  var views = {
    "map_only": {
        map: "function(doc) { emit(doc.name); }"
    },
    "map_reduce": {
        map: "function(doc) { emit([doc.type, doc.name], 1); }",
        reduce: "function(k, v, r) { var o = 0; for(var i in v) { o += v[i]; } return o; }"
    },
    "map_with_tokens": {
        map: "function(doc) { if (doc.type === '{{DOCTYPE}}') { emit(doc.name); } }",
        replace: { '{{DOCTYPE}}': 'foo' },
        replace_later: { '{{DOCTYPE}}': 'foo' }
    },
    "map_with_type": {
        map: "function(doc) { emit(doc.name); }",
        type: "bar"
    }
  };

/*
  var remote = function(method, url, data, admin) {
      var host = 'http://localhost:' + ((!!admin) ? '4985' : '4984');
      var g = new XMLHttpRequest();
      data = (data) ? JSON.stringify(data) : null;
      try {
          g.open(method, host + url, false);
          g.setRequestHeader('Content-Type', 'application/json');
          g.setRequestHeader('Accept', 'application/json');
          g.withCredentials = true;
          setTimeout(function() { g.status || g.abort(); }, 3000);
          g.send(data);
      } catch (e) {
          console.log(e);
      }
      console.log(host + url, g, g.responseText);
      console.log(g.getAllResponseHeaders());
      return g.status;
  };
*/
  var callDb = function(call) {
      var url = 'http://localhost:' + ((!!call.admin) ? '4985' : '4984') + call.url;
      return fetch(url, {
          method: call.method,
          headers: new  Headers({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }),
          credentials: 'same-origin',
          body: (call.data) ? JSON.stringify(call.data) : null
      });
  };

    var callReduce = function(prev, current) {
        console.log("callReduce", prev, current);
        if (!prev) {
          return callDb(current);
        }
        //return callDb(current);
        return prev.then(function(res) { console.log(res); return callDb(current); });
    };

  var remote = [ { method: 'GET', url: '/' }, { method: 'GET', url: '/', admin: true } ].reduce(callReduce, false);
  remote.catch(function() { delete remote; });

  if (remote) {
    remote.then(function() {
        [
           { method: 'PUT', url: '/cordova_tests/', data: { users: { 'Tester': { password: 'pass', admin_channels: [ '*' ] } } }, admin: true },
           { method: 'GET', url: '/cordova_tests/_session', data: { name: 'Tester', password: 'pass' } },
           { method: 'GET', url: '/cordova_tests/' },
           { method: 'DELETE', url: '/cordova_tests/', admin: true }
         ].reduce(callReduce, false);
    });
  }

  describe('window.cblite', function() {

    var db;

    var db2;

    it("should exist", function() {
        expect(window.cblite).toBeDefined();
    });

    it("should get info about the CBLite installed", function(done) {
      window.cblite.info(
        function(res) {
          expect(res).toEqual({
            'version': jasmine.any(Number),
            'directory': jasmine.any(String),
            'databases': jasmine.any(Array)
          });
          done();
        },
        function(res) { done.fail(JSON.stringify(res)); }
      );
    });

    it("should fail to open a missing database (explicit)", function(done) {
      window.cblite.openDatabase(
        function(res) { done.fail(JSON.stringify(res)); },
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_NotFound }));
            done();
        },
        dbName, false
      );
    });

    it("should fail to open a missing database (implicit)", function(done) {
      window.cblite.openDatabase(
        function(res) { done.fail(JSON.stringify(res)); },
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_NotFound }));
            done();
        },
        dbName
      );
    });

    it("should create and open a new database (explicit)", function(done) {
      // TODO double check that the db was actually created
      window.cblite.openDatabase(
        function(res) {
            db = res;
            expect(res).toEqual(jasmine.objectContaining({ name: dbName }));
            done();
        },
        function(res) { done.fail(JSON.stringify(res)); },
        dbName, true
      );
    });

    it("should close an open database", function(done) {
        // TODO double check that the db was actually closed
        db.closeDatabase(
            function(res) {
                db = null;
                expect(res).not.toEqual(jasmine.anything());
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); }
        );
    });

    it("should open a database that already exists", function(done) {
      // TODO what happens if you attempt to open an already open db?
      window.cblite.openDatabase(
        function(res) {
            db = res;
            expect(res).toEqual(jasmine.objectContaining({ name: dbName }));
            done();
        },
        function(res) { done.fail(JSON.stringify(res)); },
        dbName
      );
    });

    it("should allow multiple databases to be open", function(done) {
      var dbName2 = dbName + "_two";
      window.cblite.openDatabase(
        function(res) {
            db2 = res;
            expect(res).toEqual(jasmine.objectContaining({ name: dbName2 }));
            done();
        },
        function(res) { done.fail(JSON.stringify(res)); },
        dbName2, true
      );
    });

    it("should delete an existing database", function(done) {
        // TODO double check that the db was actually deleted
        db.deleteDatabase(
            function(res) {
                db = null;
                expect(res).not.toEqual(jasmine.anything());
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); }
        );
        db2.deleteDatabase(function() {}, function() {});
    });
  });

  describe('a database instance', function() {

    var db;

    var seq = 0;

    // a store of expected docs
    var mock = [];

    var addMock = function(i, doc, rev) {
        mock[i] = Object.assign({}, doc, rev);
    }

    var watch, watchId;

    beforeAll(function(done) {
        window.cblite.openDatabase(
            function(res) { db = res; done(); },
            function(res) { done.fail(JSON.stringify(res)); },
            dbName, true
        );

        watch = jasmine.createSpy('watch');
    });

    afterAll(function(done) {
        db.deleteDatabase(
            function() { db = null; done(); },
            function(res) { done.fail(JSON.stringify(res)); }
        );
    });

    it('should know its own name', function() {
        expect(db.name).toEqual(dbName);
    });

    it('should register a watch', function(done) {
        db.watch(
            function(res) {
                watch(res);
                if (!watchId) {
                    watchId = res.watch_id;
                }
                expect(res).toEqual(jasmine.objectContaining({ watch_id: jasmine.any(String) }));
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); }
        );
    });

    describe('when registering a view', function() {
        it('should succeed with a map but no reduce', function(done) {
            var view = views['map_only'];
            db.setView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_only", "1", view
            );
        });

        it('should succeed with full map/reduce', function(done) {
            var view = views['map_reduce'];
            db.setView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_reduce", "1", view
            );
        });

        it('should fail without a map', function(done) {
            db.setView(
                function(res) { done.fail(JSON.stringify(res)); },
                function(res) {
                    expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_BadRequest }));
                    done();
                },
                "no_map", "1", {}
            );
        });

        it('should accept values to replace in the map', function(done) {
            var view = views['map_with_tokens'];
            db.setView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_with_tokens", "1", { map: view.map }, { replace: view.replace }
            );
        });

        it('should replace with a newer version number', function(done) {
            var view = views['map_with_tokens'];
            db.setView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_with_tokens", "2", { map: view.map }, { replace: view.replace_later }
            );
        });

        it('should succeed with a type field set', function(done) {
            var view = views['map_with_type'];
            db.setView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_with_type", "1", { map: view.map }, { type: view.type }
            );
        });

        it('should succeed when loading from assets', function(done) {
            db.setViewFromAssets(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_from_assets", "1", "views"
            );
        });

        it('should succeed when deleted', function(done) {
            db.unsetView(
                function(res) { expect(res).not.toEqual(jasmine.anything()); done(); },
                function(res) { done.fail(JSON.stringify(res)); },
                "map_from_assets"
            );
        });

    });

    describe('when newly created', function() {
        it('should have a documentCount of 0', function(done) {
            db.documentCount(
                function(res) { expect(res).toEqual({ count: 0 }); done(); },
                function(res) { done.fail(JSON.stringify(res)); }
            );
        });

        it('should have a lastSequence number of 0', function(done) {
            db.lastSequenceNumber(
                function(res) { expect(res).toEqual({ last_seq: 0 }); done(); },
                function(res) { done.fail(JSON.stringify(res)); }
            );
        });
    });

    describe('allowing document CREATE', function() {

        it('should accept an object with a key', function(done) {
            var record = testDocs[0];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: record._id,
                        _rev: jasmine.any(String)
                    });
                    addMock(0, record, res);
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record
            );
        });

        it('should accept a JSON string with a key', function(done) {
            var record = testDocs[1];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: record._id,
                        _rev: jasmine.any(String)
                    });
                    addMock(1, record, res);
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                JSON.stringify(record)
            );
        });

        it('should reject an object whose key already exists', function(done) {
            var record = testDocs[0];
            db.add(
                function(res) { done.fail(JSON.stringify(res)); },
                function(res) {
                     expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_Conflict }));
                     done();
                },
                record
            );
        });

        it('should reject a JSON string whose key already exists', function(done) {
            var record = testDocs[0];
            db.add(
                function(res) { done.fail(JSON.stringify(res)); },
                function(res) {
                     expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_Conflict }));
                     done();
                },
                JSON.stringify(record)
            );
        });

        it('should accept an object without a key', function(done) {
            var record = testDocs[2];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: jasmine.any(String),
                        _rev: jasmine.any(String)
                    });
                    addMock(2, record, res);
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record
            );
        });

        it('should accept a JSON string without a key', function(done) {
            var record = testDocs[3];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: jasmine.any(String),
                        _rev: jasmine.any(String)
                    });
                    addMock(3, record, res);
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                JSON.stringify(record)
            );
        });

        describe('and then', function() {
            it('should have an accurate documentCount', function(done) {
                db.documentCount(
                    function(res) { expect(res).toEqual({ count: mock.length }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });

            it('should have an increasing lastSequence', function(done) {
                db.lastSequenceNumber(
                    function(res) { expect(res).toEqual({ last_seq: seq }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });
        });
    });

    describe('allowing document READ', function() {
        it('should get a record directly by its known key', function(done) {
            var record = mock[0];
            db.get(
                function(res) {
                    expect(res).toEqual(jasmine.objectContaining(record));
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record._id
            );
        });

        it('should get a record directly by its auto key', function(done) {
            var record = mock[2];
            db.get(
                function(res) {
                    expect(res).toEqual(jasmine.objectContaining(record));
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record._id
            );
        });

        it('should return nothing on unknown key', function(done) {
            db.get(
                function(res) {
                    expect(res).not.toEqual(jasmine.anything());
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                "not_a_real_record"
            );
        });
    });

    describe('allowing document UPDATE', function() {
        it('should succeed when revision matches', function(done) {
            var record = mock[0];
            var modified = Object.assign({}, record, { name: 'modified' });

            db.update(
                function(res) {
                    expect(res).toEqual({
                        _id: jasmine.any(String),
                        _rev: jasmine.any(String)
                    });
                    expect(res._rev).not.toEqual(record._rev);
                    addMock(0, modified, res);
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                modified
            );
        });

        it('should fail when revision does not match', function(done) {
            var record = mock[1];
            var modified = Object.assign({}, record, { name: 'modified' });
            db.update(
                function(res) {
                    // we have a new revision, but let's try with the old one
                    modified.name = 'modified again';
                    seq++;
                    db.update(
                        function(res) { done.fail(JSON.stringify(res)); },
                        function(res) {
                             expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_Conflict }));
                             done();
                        },
                        modified
                    );
                },
                function(res) { done.fail(JSON.stringify(res)); },
                modified
            );
        });

        it('should fail when no revision is provided', function(done) {
            var record = mock[1];
            var modified = Object.assign({}, record, { name: 'modified' });
            delete modified._rev;

            db.update(
                function(res) { done.fail(JSON.stringify(res)); },
                function(res) {
                     expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_Conflict }));
                     done();
                },
                modified
            );
        });

        it('should fail when no _id is provided', function(done) {
            var record = mock[1];
            var modified = Object.assign({}, record, { name: 'modified' });
            delete modified._id;

            db.update(
                function(res) { done.fail(JSON.stringify(res)); },
                function(res) {
                     expect(res).toEqual(jasmine.objectContaining({ code: window.cblite.res_BadRequest }));
                     done();
                },
                modified
            );
        });

        describe('and then', function() {
            it('should retain the edits', function(done) {
                var record = mock[0];
                db.get(
                    function(res) {
                        expect(res).toEqual(record);
                        done();
                    },
                    function(res) { done.fail(JSON.stringify(res)); },
                    record._id
                );

            });

            it('should have an accurate documentCount', function(done) {
                db.documentCount(
                    function(res) { expect(res).toEqual({ count: mock.length }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });

            it('should have an increasing lastSequence', function(done) {
                db.lastSequenceNumber(
                    function(res) { expect(res).toEqual({ last_seq: seq }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });
        });
    });

    describe('allowing document DELETE', function() {
        it('should delete a record directly by its key', function(done) {
            // use the last one, so it can most easily be popped from the mock
            var record = mock[mock.length - 1];
            db.remove(
                function(res) {
                    expect(res).not.toEqual(jasmine.anything());
                    mock.pop();
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record._id
            );
        });

        it('should succeed if record is already deleted', function(done) {
            db.remove(
               function(res) {
                    expect(res).not.toEqual(jasmine.anything());
                    done();
                },
                function(res) { done.fail('FAIL: ' + JSON.stringify(res)); },
                'not_a_real_record'
            );
        });

        describe('and then', function() {
            it('should have an accurate documentCount', function(done) {
                db.documentCount(
                    function(res) { expect(res).toEqual({ count: mock.length }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });

            it('should have an increasing lastSequence', function(done) {
                db.lastSequenceNumber(
                    function(res) { expect(res).toEqual({ last_seq: seq }); done(); },
                    function(res) { done.fail(JSON.stringify(res)); }
                );
            });
        });
    });

    it('should cancel a running watch', function(done) {
        db.stopWatch(
            function(res) {
                expect(res).not.toEqual(jasmine.anything());
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); },
            watchId
        );
    });

    it('should have captured changes', function() {
        // the sequence + the initial call should match the number of change
        expect(watch.calls.count()).toEqual(seq + 1);
    });

  });

};

/*
compactDatabase

replicate
stopReplicate

watch
stopWatch

setView
setViewFromAssets
getFromView
liveQuery
stopLiveQuery
getAll

*/