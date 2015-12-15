var assert = require('assert');
var restify = require('restify');
var Q = require('q');

var _range;

process.env.LINCS_DEVEL = 'true';

var client = restify.createJsonClient({
    version: '*',
    url: 'http://127.0.0.1:8084'
});

// start up the service before we run any tests!

before(function(done) {
    require('../bin/app');
    done();
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
  it.skip('retrieves range of numerical indices', function(done) {
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

  it.skip('retrieves range of documents by NID range', function(done) {
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

  it('retrieves range of document summaries by document range (1..N)', function(done) {
    client.get('/LINCS/summaries?skip=0&limit=10', function(err, req, res, data) {
      if(err) throw(err);
      checkResponse(res);
      assert.equal(data.length, 10);
      done();
    });
  });

  it('retrieves range of document summaries by key fragment', function(done) {
    client.get('/LINCS/summaries?key=AML001_CD34_24H_X1', function(err, req, res, data) {
      if(err) throw(err);
      checkResponse(res);
      assert.equal(data.length, 10);
      done();
    });
  });

  //lincs.instSamePlateVehicles("RAD001_MCF7_24H_X3_F1B5_DUO52HI53LO:N02")
  it('retrieves an instance', function(done) {
    client.get('/LINCS/instances/12', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
        checkResponse(res);
        assert.ok(data.metadata);
        done();
      }
    });
  });
  
  it('retrieves control data for given instance', function(done) {
    client.get('/LINCS/instances/12/controls', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
        checkResponse(res);
        assert.ok(data[0].value.metadata);
        assert.equal(data.length, 15);
        done();
      }
    });
  });

  it('retrieves all instances with the specified perturbation', function(done) {
    client.get('/LINCS/instances?cell="SNUC4"&pert="Rottlerin"&dose=9.68&duration=6', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            checkResponse(res);
            assert.ok(data[0]);
            assert.equal(data.length, 2);
            done();
      }
    });
  });
  
  it('retrieves all instances with the specified perturbation but any dose or duration', function(done) {
    client.get('/LINCS/instances?cell="SNUC4"&pert="Rottlerin"', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            checkResponse(res);
            assert.ok(data[0]);
            assert.equal(data.length, 2);
            done();
      }
    });
  });

  it('inserts instance document with numerical ID', function(done) {
    client.post('/LINCS/instances', {id: 1, metadata: {cell: "A375", perturbagen: "BRD-K73037408", duration: 24, dose: 2}, 
                                 gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                 data: [12, 3, 4.1],
                                 type: "test_instance"}, 
    function(err, req, res,id) {
      if (err) {
          throw err;
      } else {
          checkResponse(res);
          assert.ok(id);
          done();
      }
    });
  });

  it('inserts instance document with string ID', function(done) {
    client.post('/LINCS/instances', {id: 'one', metadata: {cell: "A375", perturbagen: "BRD-K73037408", duration: 24, dose: 2}, 
                                 gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                 data: [12, 3, 4.1],
                                 type: "test_instance"}, 
    function(err, req, res, id) {

      if (err) {
          throw err;
      } else {
          checkResponse(res);
          assert.ok(id);
          done();
      }
    });
  });

  it('returns an informative error if required instance fields not provided.', function(done) {
    client.post('/LINCS/instances', {id: 1, metadata: {cell: "A375", perturbagen: "BRD-K73037408", duration: 24, dose: 2}, 
                                 gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                 data: [12, 3, 4.1]}, // no type!
    function(err, req, res, data) {
          assert.ok(err);
          done();
    });
  });


  it('inserts zscore document', function(done) {
    client.post('/LINCS/pert', {cell: "A375", perturbagen: "BRD-K73037408", duration: 24, dose: 2,  
                                      gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                      data: [12, 3, 4.1],
                                      type: "test_sig",
                                      method: "test",
                                      gold: false}, 
    function(err, req, res, id) {
      if (err) {
          throw err;
      } else {
          checkResponse(res);
          assert.ok(id);
          done();
      }
    });
  });

  it('returns an informative error if required pert fields not provided.', function(done) {
    client.post('/LINCS/pert', {cell: "A375", perturbagen: "BRD-K73037408", dose: 2,  
                                      gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                      data: [12, 3, 4.1],
                                      type: "test_sig",
                                      method: "test",
                                      gold: false}, // note no duration!
    function(err, req, res, data) {
          assert.ok(err);
          done();
    });
  });
});

var checkResponse = function(res) {
  if(res.statusCode == 500 || res.statusCode == 400) {
    throw(new Error(res.body));
  }
};
