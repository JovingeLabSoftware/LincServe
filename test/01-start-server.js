// start up the service before we run any tests!

restify = require('restify');
assert = require('assert');

before(function(done) {
    require('../bin/app');
    done();
});
