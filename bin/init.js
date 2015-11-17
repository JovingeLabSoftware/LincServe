var lincs = require("../node_modules/lincs/lib/lincs");
var config = require("../node_modules/lincs/config");
var Q = require('q');


var skip = 100000;
var limit = 10;
var q = 'SELECT metadata.* FROM ' + config.couchdb.bucket + ' OFFSET ' + skip + ' LIMIT ' + limit;
lincs.query(q)
.then(function(res) {
	console.log(res.length)
}).then(function() {
	process.exit(0);
}).catch(function(err) {
	console.log(err)
	process.exit(1);
});
