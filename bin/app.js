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
 * @api {get} /LINCS  Get some documentation on endpoints.
 * @apiName Root
 * @apiGroup Root
 *
 * @apiSuccess {string} response  Some useful information.
 */
server.get('/LINCS', function(req, res){
    res.send(200, "Current endpoints: /LINCS/nixrange.  See http://jovingelabsoftware.github.io/CouchLincs/api for details");
});

/**
 * @api {get} /LINCS/nixrange Request range of numerical index.
 * @apiDescription Remember that the numerical indices are used for 
 *  rapid paging/chunking.  They are NOT necessarily uniqe, NOT 
 *  contiguous, and NOT in any sort of order.  But they are FAST.
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

/**
 * @api {POST} /LINCS/summaries Request summary docs by numerical index range 
 * @apiName summaries
 * @apiGroup LINCS
 * @apiDescription Remember that the numerical indices are used for 
 *  rapid paging/chunking.  They are NOT necessarily uniqe, NOT 
 *  contiguous, and NOT in any sort of order.  But they are FAST.
 *
 * @apiParam {Number} first Starting numerical index.
 * @apiParam {Number} last Ending numerical index.
 *
 * @apiSuccess {string} summaries Summary docs in JSON format
 */
server.post('/LINCS/summaries', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.getByNIX(req.params.first, req.params.last, function(err, data) {
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

