var Q = require('q');
var config = require('../config');
var restify = require('restify');
var lincs = require('lincs')

var server = restify.createServer({
  name: 'LINCS',
  version: '0.0.1'
});

server.use(restify.bodyParser());
server.use(restify.fullResponse());
server.use(restify.CORS());
server.use(restify.queryParser());


/**
 * @api {get} / Root.  Verify server up and receive useful advice.
 * @apiName Root
 * @apiGroup Root
 *
 * @apiSuccess {string} OK.  Send GET to /LINCS for further documentation.
 */
server.get('/', function(req, res){
    res.send(200, "OK.  Send GET to /LINCS for further documentation.");
});

/**
 * @api {get} /LINCS/nixrange Request range of numerical index
 * @apiName nixrange
 * @apiGroup LINCS
 *
 * @apiSuccess {integer} first Smallest index
 * @apiSuccess {integer} last  Largest index
 */
server.get('/LINCS/nixrange', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.getNIXRange(function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
});

var port = 8080; // should get from config file some day

server.listen(port, function() {
    console.log('\t%s listening at %s', server.name, server.url);
});

