var assert = require('assert');
var restify = require('restify');
var Q = require('q');

var _range;

process.env.LINCS_DEVEL = 'true';
var port = process.env.COUCHLINCS_PORT || 8084;

var client = restify.createJsonClient({
    version: '*',
    url: 'http://127.0.0.1:' + port
});

//convenience function for formatting API query strings
var queryString = function(q, f, s, l) {
  q = q || null; f = f || null; s 
  = s || null; l = l || null;
  var qs = '';
  qs += (q == null) ? "" : `&q=${JSON.stringify(q)}`;
  qs += (f == null) ? "" : `&f=${JSON.stringify(f)}`;
  qs += (l == null) ? "" : `&l=${l}`;
  qs += (s == null) ? "" : `&s=${s}`;
  return(qs.slice(1)); // drop leading &.  reduces logic above.
};


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
  it('retrieves data for one instance by distil_id', function(done) {
    this.timeout(5000);
    var qs = queryString({distil_id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05'},  // query
                          ['metadata.pert_id'], // fields
                          0,                    // skip
                          1);                   // limit
    var url = encodeURI(`/LINCS/instances?${qs}`)
    client.get(url, function(err, req, res, data) {
      if(err) throw(err);
      console.log(qs)
      checkResponse(res);
      assert.equal(data[0].pert_id,  "BRD-A64228451");
      done();
    });
  });

  it('retrieves several instances by ids', function(done) {
    client.get(encodeURI('/LINCS/instances?ids=[5,6,7]'), function(err, req, res, data) {
      if(err) throw(err);
      checkResponse(res);
      assert.equal(data.length, 3);
      done();
    });
  });

  it('retrieves specified fields of several instances by ids', function(done) {
    var url = encodeURI(`/LINCS/instances?ids=[5,6,7]&f=["metadata.pert_desc", "metadata.pert_type"]`);
    client.get(url, function(err, req, res, data) {
      if(err) throw(err);
      checkResponse(res);
      assert.equal(data.length, 3);
      assert.ok(data[0].pert_type);
      done();
    });
  });

  it('retrieves data for multiple instances by distil_id', function(done) {
    var keys = ["HSF045_HEK293T_48H_X1_B12:H21", "BRAF001_HEK293T_24H_X2_B10:E24"];
    client.post('/LINCS/instances/distil_id', 
                  {ids: keys, fields:["metadata.pert_desc", 
                  "metadata.pert_id"]}, 
           function(err, req, res, data) {
      if(err) throw(err);
      checkResponse(data);
      assert.equal(data.length, 2);
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

  it.skip('retrieves all instances with the specified perturbation', function(done) {
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
  
  it.skip('retrieves all instances with the specified perturbation but any dose or duration', function(done) {
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

  it.skip('inserts instance document with numerical ID', function(done) {
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

  it.skip('inserts instance document with string ID', function(done) {
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

  it.skip('returns an informative error if required instance fields not provided.', function(done) {
    client.post('/LINCS/instances', {id: 1, metadata: {cell: "A375", perturbagen: "BRD-K73037408", duration: 24, dose: 2}, 
                                 gene_ids: ['GENE1', 'GENE2', 'GENE3'],
                                 data: [12, 3, 4.1]}, // no type!
    function(err, req, res, data) {
          assert.ok(err);
          done();
    });
  });


  it.skip('inserts zscore document', function(done) {
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

  it.skip('returns an informative error if required pert fields not provided.', function(done) {
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
  
  it.skip('retrieves the appropriate shRNA controls.', function(done) {

    client.get('/LINCS/instances/5/sh_controls', function(err, req, res, data) {
      if (err) {
          throw err;
      } else {
            assert.ok(data[0]);
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
