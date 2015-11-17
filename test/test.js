var Q = require('q');


var client = restify.createJsonClient({
    version: '*',
    url: 'http://127.0.0.1:8080'
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
    client.get('/LINCS/nixrange', function(err, req, res, data) {
      if (err) {
          throw new Error(err);
      }
      else {
          assert(data.min > 0);
          assert(data.max > 0);
          done();
      }
    });
  });

  it('retrieves list of data types', function(done) {
  client.get('/LINCS/nixrange', function(err, req, res, data) {
    if (err) {
        throw new Error(err);
    } else {
        client.post('/LINCS/summaries', {first: data.min, last: data.min+10000000000}, function(err, req, res, data) {
          assert.ok(data[0]);
          done();
        })
    }
  });
});

});