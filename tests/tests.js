exports.defineAutoTests = function() {

  var dbName = 'cb-tests';

  var testDocs = [
    { _id: "1", name: "one", type: "foo" },
    { _id: "2", name: "two", type: "bar" },
    { name: "three", type: "foo" },
    { name: "four", type: "bar" }
  ];

  describe('window.cblite', function() {

    var db;

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
            expect(res).toEqual(jasmine.objectContaining({ code: 404 }));
            done();
        },
        dbName, false
      );
    });

    it("should fail to open a missing database (implicit)", function(done) {
      window.cblite.openDatabase(
        function(res) { done.fail(JSON.stringify(res)); },
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ code: 404 }));
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
    });
  });

  describe('a database instance', function() {

    var db;

    beforeAll(function(done) {
        window.cblite.openDatabase(
            function(res) { db = res; done(); },
            function(res) { done.fail(JSON.stringify(res)); },
            dbName, true
        );
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

    describe('that supports CRUD', function() {

        var count = 0;
        var seq = 0;

        it('should insert a document with a key (object)', function(done) {
            var record = testDocs[0];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: record._id,
                        _rev: jasmine.any(String)
                    });
                    count++;
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record
            );
        });

        it('should insert a document with a key (string)', function(done) {
            var record = testDocs[1];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: record._id,
                        _rev: jasmine.any(String)
                    });
                    count++;
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                JSON.stringify(record)
            );
        });

        it('should insert a document without a key (object)', function(done) {
            var record = testDocs[2];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: jasmine.any(String),
                        _rev: jasmine.any(String)
                    });
                    count++;
                    seq++;
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record
            );
        });

        it('should insert a document without a key (string)', function(done) {
            var record = testDocs[3];
            db.add(
                function(res) {
                    expect(res).toEqual({
                        _id: jasmine.any(String),
                        _rev: jasmine.any(String)
                    });
                    count++;
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
                    function(res) { expect(res).toEqual({ count: count }); done(); },
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

        it('should get a record directly by its key', function(done) {
            var record = testDocs[0];
            db.get(
                function(res) {
                    expect(res).toEqual(jasmine.objectContaining(record));
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); },
                record._id
            );
        });

    });

  });

};

/*
compactDatabase

replicate
stopReplicate

setView
setViewFromAssets
getFromView
stopLiveQuery
getAll

*/