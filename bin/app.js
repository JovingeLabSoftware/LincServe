var Q = require('q');
var config = require('../config');
var restify = require('restify');
var lincs = require('couchlincs');

var server = restify.createServer({
  name: 'LINCS',
  version: '0.0.1'
});

server.use(restify.bodyParser());
server.use(restify.fullResponse());
server.use(restify.CORS());
server.use(restify.queryParser());
restify.defaultResponseHeaders = function(data) {
    this.header("Access-Control-Allow-Origin", "*");
    this.header("Access-Control-Allow-Headers", "X-Requested-With");
    this.contentType = 'json';
};


/**
 * @api {get} / Root.  Verify server up and receive useful advice.
 * @apiName Root
 * @apiGroup Root
 *
 * @apiExample {curl} Example usage:
 *           curl http://localhost:8080/
 * @apiSuccess {string} response
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * OK.  Send GET to /LINCS for further documentation.
 * 
 */
server.get('/', function(req, res){
    res.send(200, "OK!  Send GET to /LINCS for further documentation.");
});

/**
 * @api {get} /LINCS  Get some documentation on endpoints.
 * @apiName Root
 * @apiGroup Root
 *
 * @apiSuccess {string} response  Some useful information.
 */
server.get('/LINCS', function(req, res){
    res.send(200, "Current endpoints: /LINCS/instances.  See http://jovingelabsoftware.github.io/CouchLincs/api for details");
});

/**
 * @api {GET} /LINCS/instances/:id Request instance by id 
 * @apiName instanceById
 * @apiGroup LINCS
 * @apiDescription Fetch data for a given instance by id
 * @apiParam {String} id Id of instance
 * @apiExample {curl} Example usage:
 *           curl localhost:8080/LINCS/instances/2
 *
 * @apiSuccess {Object} data data docs in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * Content-Type: application/json
 * {
 *   "data": { ... },
 *   "metadata": { ... },
 *   "timestamp": "2015-12-18 03:52:52",
 *   "id": "1230884"
 * }   
 */
server.get('/LINCS/instances/:id', function(req, res){
    var key = req.params.id;
    lincs.get(key, null, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data[0]);
        }
    });
});

/**
 * @api {GET} /LINCS/instances Query instances 
 * @apiName instanceQuery
 * @apiGroup LINCS
 * @apiDescription Fetch data for instances matching query.  Either ids or q 
 *  should be specified
 * @apiParam {String[]} [ids] Optional explicit list of primary ids
 * @apiParam {String[]} [q] Optional query in form of field: value pairs, as in:
 *                      q={"pert_desc": "celecoxib", "pert_type": "trt_cp"}.  
 *                      Note that fields are assumed to be in metadata slot.
 *                      Querying outside the metadata is not possible.
 * @apiParam {String[]} [f] Optional list of fields to return, e.g. 
 *                         [metadata.pert_desc, gene_ids]
 *                      Note that parent field must be explicitly declared 
 *                      (e.g. metadata), so that top level slots (data, gene_ids)
 *                      can be requested and returned.
 * @apiParam {Number} s Number of records to skip (for paging)
 * @apiParam {Number} l Number of records to return (limit)
 * @apiExample {curl} Example usage:
 *           curl -G "http://localhost:8080/LINCS/instances" --data-urlencode "ids=[1,2,3]" \
 *              --data-urlencode f='["metadata.pert_type"]'
 *           curl -G "http://localhost:8082/LINCS/instances" --data-urlencode q='{"pert_desc": "celecoxib"}' \
 *              --data-urlencode f='["metadata.pert_type"]' --data l=10 --data s=10
 * @apiSuccess {Object} data data docs in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * Content-Type: application/json
 * {
 *   [
 *     {
 *       "id":"1",
 *       "pert_type":"trt_cp"
 *       },
 *       {
 *          "id":"2",
 *          "pert_type":"trt_cp"
 *           
 *       },
 *       {
 *         "id":"3",
 *         "pert_type":"trt_cp"
 *       }
 *     ]
 * }   
 */
server.get('/LINCS/instances', function(req, res){
    var query = req.params;
    if(query.ids) {
        var f =  has(query, f) ? JSON.parse(query.f) : null;
        lincs.get(JSON.parse(query.ids), f, function(err, data) {
            if(err) {
                res.send(400, err);
            } else {
                res.send(200, data);
            }
        });
    } else if(query.q) {
        var f = query.f ? JSON.parse(query.f) : null;
        var s = query.s ? JSON.parse(query.s) : null;
        var l = query.l ? JSON.parse(query.l) : null;
        lincs.instanceQuery(JSON.parse(query.q), f, s, l, function(err, data) {
            if(err) {
                res.send(400, err);
            } else {
                res.send(200, data);
            }
        });
    } else {
        res.send(400, "ERROR: You must provide either ids (array of primary ids)" +
                        " or q (query in form of field value pairs as JSON)");
    }
});

var has = function(o, f) {
    if(typeof(o) == "string") {
      return(typeof(JSON.parse(o).f) != "undefined")
    } else {
      return(typeof(o.f) != "undefined")
    }
}

/**
 * @api {POST} /LINCS/instances/distil_id data by distil_id (multi) 
 * @apiName distilIdsData
 * @apiGroup LINCS
 * @apiDescription Fetch metadata for given instance by distil_id.  We use POST
 * here because keys are long and could quickly exceed GET query string limits. 
 * The same data can be achieved with the /LINCS/instances GET endpoint using the 'q'
 * parameter, but that may fail with large numbers of distil_ids due to query 
 * string length limits imposed by many clients.
 * @apiParam {string[]} ids distilIds of instances
 * @apiParam {string[]} fields fields to return (defaults to all data)
 * @apiExample {curl} Example usage:
 *  curl -d '{"ids": ["CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05", \
 *        "CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05"]}' \
 *        localhost:8080/LINCS/instances/distil_id \
 *        -H "Content-Type: application/json"  
 *
 * @apiSuccess {Object} data docs in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * Content-Type: application/json
 * [  
 * {
 *    "data": { ... }
 *    "gene_ids": { ... }
 *    "metadata": { ... },
 *    "id": "312240"
 *  } 
 * ... // truncated
 * ]
 */
server.post('/LINCS/instances/distil_id', function(req, res){
    var ids = req.params.ids;
    var fields = req.params.fields || "*";
    lincs.instanceQuery({"distil_id": ids}, fields, null, null, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
});





/**
 * @api {POST} /LINCS/pert Create a perturbation data document
 * @apiName createPerturbation
 * @apiGroup LINCS
 * @apiDescription Creates a data document for a particular perturbation &
 *                 calculation method
 * 
 * @apiParam {String} perturbagen name of perturbagen
 * @apiParam {Numeric} dose dose (unitless)
 * @apiParam {Numeric} duration duration (unitless)
 * @apiParam {String} cell cell line used
 * @apiParam {String} method calculation method used, e.g. "zsvc_plate"
 * @apiParam {Boolean} gold is this a gold signature score?
 * @apiParam {String[]} gene_ids from lincs
 * @apiParam {Numeric[]} data the scores (one per gene)
 *
 * @apiSuccess {String} Id of created object
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 201 Created
 * {
 *  id: 1
 * }
 */
server.post('/LINCS/pert', function(req, res) {
    if(!checkParams(req.params, ['perturbagen', 'dose', 'duration', 'cell',
                          'method', 'gold', 'gene_ids', 'data'])) {
        res.send(400, "Creating pert document requires specification of " +
                      "perturbagen, dose, cell, method, gold, gene_ids, data")                      
    } else {
        lincs.savePert(req.params, function(err, data) {
            if(err) {
                res.send(400, err);
            } else {
                res.send(200, data);
            }
        });
    }
});

                                           
/**
 * @api {POST} /LINCS/instances Save instance data to server 
 * @apiName postInstance
 * @apiGroup LINCS
 * @apiDescription Stores instance (e.g. level 2 data) on the server. Do NOT use this
 *                    endpoint to save calculated scores (use /LINCS/pert for that).
 *
 * @apiParam {String} id desired id (key) of document
 * @apiParam {String} metadata JSON from lincs
 * @apiParam {String} type  Type of data, e.g. "q2norm"
 * @apiParam {String[]} gene_ids from lincs
 * @apiParam {Numeric[]} data the expression data
 *
 * @apiSuccess {String} response response
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * }
 */
server.post('/LINCS/instances', function(req, res){
    if(!checkParams(req.params, ['id', 'gene_ids', 'metadata', 'data', 'type'])) {
        res.send(400, "Creating instance document requires POSTing the following " +
                      "parameters: id, gene_ids, data, metadata, type"); 
    } else {
        var doc = {gene_ids: req.params.gene_ids, 
                   metadata: req.params.metadata,
                   data: req.params.data,
                   type: req.params.type,
                   gold: req.params.gold};

        lincs.saveInstance(req.params.id, doc, function(err, data) {
            if(err) {
                res.send(400, err);
            } else {
                res.send(200, data);
            }
        });
    }
});

var dequote = function(x) {
  for (var key in x) {
    if (x.hasOwnProperty(key)) {
      if(typeof(x[key]) === 'string') {
        x[key] = x[key].replace(/\"/g, '');
      }
    }
  }
  return(x);
};

var checkParams = function(obj, vars) {
    var ok = true;
    vars.forEach(function(v) {
        if(typeof(obj[[v]]) == "undefined") {
            ok = false;
        } 
    });
    return(ok);
};


var port = config.port; 
if(process.env.COUCHLINCS_PORT)
   port = process.env.COUCHLINCS_PORT;


server.listen(port, function() {
    console.log('\t%s listening at %s', server.name, server.url);
});
