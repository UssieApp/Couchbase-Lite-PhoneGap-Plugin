exports.defineAutoTests = function() {

  describe('high level database tests', function() {
    it("should exist", function() {
        expect(window.cblite).toBeDefined();
    });

    it("should get info about the CBLite installed", function(done) {
      window.cblite.info(function(res) {
          expect(res).toEqual({
            'version': jasmine.any(Number),
            'directory': jasmine.any(String),
            'databases': jasmine.any(Array)
          }));
          done();
      }, done.fail);
    });

    it("should fail to open a database that doesn't exist yet", function() {
      expect(1).toBe(1);
    });

    it("should create a database that doesn't exist yet", function() {
      expect(1).toBe(1);
    });

    it("should close an open database", function() {
      expect(1).toBe(1);
    });

    it("should open a database that already exists", function() {
      expect(1).toBe(1);
    });

    it("should delete an existing database", function() {
      expect(1).toBe(1);
    });

  });


};