var assert = require('assert');
var restify = require('restify');
var Q = require('q');

var _range;

process.env.LINCS_DEVEL = 'true';

var client = restify.createJsonClient({
    version: '*',
    url: 'http://127.0.0.1:8083'
});

describe('Server up', function() {
  it('should get a 200 response', function(done) {
    client.get('/', function(err, req, res, data) {
      if (err) {
          throw new Error(err);
      }
      else {
          assert(res.statusCode==200);
          done();
      }
    });
  });
});

describe('LINCS methods', function() {
  it('retrieves range of numerical indices', function(done) {
    client.get('/LINCS/nidrange', function(err, req, res, data) {
      if (err) {
          throw new Error(err);
      }
      else {
          _range = data;
          assert(data.min > 0);
          assert(data.max > 0);
          done();
      }
    });
  });

  it('retrieves range of documents by NID range', function(done) {
  client.get('/LINCS/nidrange', function(err, req, res, data) {
      if (err) {
          throw new Error(err);
      } else {
          // fetch about 0.001% of documents.
          var inc = Math.floor((_range.max - _range.min) / 1000000);
          client.get('/LINCS/summaries/nid?first=' + (data.max-inc) + "&last=" + data.max, function(err, req, res, data) {
            if(err) {
               throw(err);
            }
            assert.ok(data[0]);
            done();
          })
      }
    });
  });

  it('retrieves range of documents by document index (1..N)', function(done) {
  client.get('/LINCS/nidrange', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
          client.get('/LINCS/summaries?skip=0&limit=' + 100, function(err, req, res, data) {
            if(err) throw(err);
            checkResponse(res);
            assert.ok(data[0]);
            assert.equal(data.length, 100);
            done();
          });
      }
    });
  });

  //["A375","BRD-K73037408",2.5,6] "BMP7", 100, 2, 0, 5)
  
  it('retrieves all instances with the specified perturbation', function(done) {
  client.get('/LINCS/instances?cell="A375"&pert="BRD-K73037408"&dose=2.5&duration=6', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            checkResponse(res);
            assert.ok(data[0]);
            assert.equal(data.length, 9);
            done();
      }
    });
  });
  
  it('retrieves all instances with the specified perturbation but any dose or duration', function(done) {
  client.get('/LINCS/instances?cell="A375"&pert="BRD-K73037408"', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            checkResponse(res);
            assert.ok(data[0]);
            assert.equal(data.length, 53);
            done();
      }
    });
  });

  it('inserts zscore document', function(done) {
  client.post('/LINCS/zscores', {cell: "A375", pert: "BRD-K73037408", duration: 24, dose: 2,  
                                        gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                        zscores: [12, 3, 4.1],
                                        type: "test_sig",
                                        gold: false}, 
      function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            checkResponse(res);
            assert.ok(data.cas);
            done();
      }
    });
  });
});

var checkResponse = function(res) {
  if(res.statusCode == 500 || res.statusCode == 400) {
    throw(new Error(res.body));
  }
};
