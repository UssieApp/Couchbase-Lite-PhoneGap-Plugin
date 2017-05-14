exports.defineAutoTests = function() {

  var dbName = 'cb-tests';

  var testDocs = [
    // docs with keys
    { _id: "1", name: "one", type: "foo" },
    { _id: "2", name: "two", type: "bar" },
    // docs without keys
    { name: "three", type: "foo" },
    { name: "four", type: "bar" }
  ];

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
                    console.log(JSON.stringify(mock));
                    mock.pop();
                    console.log(JSON.stringify(mock));
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

    describe('using a changes listener', function() {

        var watchId;

        var watch = {
            result: function(res) {
                expect(res).toEqual({ watch_id: jasmine.any(String) });
            }
        };

        spyOn(watched, 'result').and.callThrough();

        it('should register a watch', function(done) {
            db.watch(
                function(res) {
                    watch.result(res);
                    done();
                },
                function(res) { done.fail(JSON.stringify(res)); }
            );
        });

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