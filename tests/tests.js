exports.defineAutoTests = function() {

  describe('window.cblite', function() {

    var db;

    var dbName = 'cb-tests';

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
        done.fail);
    });

    it("should fail to open a database that doesn't exist yet (explicit)", function(done) {
      window.cblite.openDatabase(
        function(res) { done.fail(JSON.stringify(res)); },
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ code: 404 }));
            done();
        },
        dbName, false);
    });

    it("should fail to open a database that doesn't exist yet (implicit)", function(done) {
      window.cblite.openDatabase(
        function(res) { done.fail(JSON.stringify(res)); },
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ code: 404 }));
            done();
        },
        dbName);
    });

    it("should create and open a database that doesn't exist yet (explicit)", function(done) {
      // TODO double check that the db was actually created
      window.cblite.openDatabase(
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ name: dbName }));
            done();
        },
        function(res) { done.fail(JSON.stringify(res)); },
        dbName, true);
    });

    it("should close an open database", function(done) {
        // TODO double check that the db was actually closed
        db.closeDatabase(
            function(res) {
                expects(res).not.toBeDefined();
                db = null;
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); }
        );
    });

    it("should open a database that already exists", function(done) {
      window.cblite.openDatabase(
        function(res) {
            expect(res).toEqual(jasmine.objectContaining({ name: dbName }));
            done();
        },
        function(res) { done.fail(JSON.stringify(res)); },
        dbName);
    });

    it("should delete an existing database", function(done) {
        // TODO double check that the db was actually deleted
        db.deleteDatabase(
            function(res) {
                expects(res).not.toBeDefined();
                db = null;
                done();
            },
            function(res) { done.fail(JSON.stringify(res)); }
        );
    });

  });


};
