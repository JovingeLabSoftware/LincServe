var Q = require('q');
var config = require('../config');
var restify = require('restify');
var lincs = require('lincs');

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
    res.send(200, "Current endpoints: /LINCS/nidrange, /LINCS/summaries, /LINCS/summaries/nid.  See http://jovingelabsoftware.github.io/CouchLincs/api for details");
});

/**
 * @api {get} /LINCS/nidrange Request range of numerical index.
 * @apiDescription Remember that the numerical indices are used for 
 *  rapid paging/chunking.  They are NOT necessarily uniqe, NOT 
 *  contiguous, and NOT in any sort of order.  But they are FAST.
 * @apiName nixrange
 * @apiGroup LINCS
 *
 * @apiSuccess {integer} first Smallest index
 * @apiSuccess {integer} last  Largest index
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * [ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',
 *  summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },
 * { id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',
 *  summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]
 * }
 */
server.get('/LINCS/nidrange', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.getNIDRange(function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
});

/**
 * @api {GET} /LINCS/summaries/nid Request summary docs by numerical id range 
 * @apiName summaries_nid
 * @apiGroup LINCS
 * @apiDescription Remember that the numerical ids are used for 
 *  rapid paging/chunking.  They are NOT necessarily uniqe, NOT 
 *  contiguous, and NOT in any sort of order.  But they are FAST.
 *
 * @apiParam {Number} first Starting numerical index.
 * @apiParam {Number} last Ending numerical index.
 *
 * @apiSuccess {string} summaries Summary docs in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * [ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',
 *  summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },
 * { id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',
 *  summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]
 * }
 */

server.get('/LINCS/summaries/nid', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.getSummaries(req.params.first, req.params.last, true, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
        	var result = [];
        	data.forEach(function(d) {
        		result.push({id: d.id, summary: d.value})
        	})
            res.send(200, result);
        }
    });
});


/**
 * @api {GET} /LINCS/summaries Request summary docs by document index (1..N) 
 * @apiName summaries
 * @apiGroup LINCS
 * @apiDescription Remember that the numerical ids are used for 
 *  rapid paging/chunking.  They are NOT necessarily uniqe, NOT 
 *  contiguous, and NOT in any sort of order.  But they are FAST.
 *
 * @apiParam {Number} skip Starting numerical index.
 * @apiParam {Number} limit Ending numerical index.
 *
 * @apiSuccess {string} summaries Summary docs in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * [ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',
 *  summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },
 *   { id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',
 *  summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]
 * } 
 */

server.get('/LINCS/summaries', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    var _first = req.params.skip;
    var _last = Number(req.params.skip) + Number(req.params.limit);
    lincs.getSummaries(_first, _last, false, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
        	var result = [];
        	data.forEach(function(d) {
        		result.push({id: d.id, summary: d.value})
        	})

            res.send(200, result);
        }
    });
});

/**
 * @api {GET} /LINCS/instances Retrieve instance ids by perturbagen or range
 * @apiName getInstance
 * @apiGroup LINCS
 * @apiDescription Retrieves instance ids based on range of perturbagen or
 * index.  Note: if perturbagen is specified, cell line must be specified 
 * (because this function queries a view with compound key).  Similarly,
 * if dose and duration are specified, cell line and perturbagen must be also.
 * 
 * @apiParam {String} pert Name of perturbagen.  Optional (but see above).
 * @apiParam {String} cell Name of cell line.  Optional (but see above).
 * @apiParam {Numeric} dose Dose, without units.  Optional (but see above).
 * @apiParam {Numeric} duration Duration, without units.  Optional (but see above).
 *
 * @apiSuccess {string} instances Instance ids  in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * [ { key: [ 'A375', 'BRD-K73037408', 2.5, 6 ],                                                                                  
 *    value:                                                                                                                     
 *     { distil_id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A08',                                                                   
 *       vehicle: 'DMSO' },                                                                                                      
 *    id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A08' },                                                                           
 *  { key: [ 'A375', 'BRD-K73037408', 2.5, 6 ],                                                                                  
 *    value:                                                                                                                     
 *     { distil_id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A16',                                                                   
 *       vehicle: 'DMSO' },                                                                                                      
 *    id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A16' },   
 * 
 *     "...truncated..."
 * ]
 * }
 */
server.get('/LINCS/instances', function(req, res) {
    req.params = dequote(req.params);
    var limit = req.params.limit || 1000;
    var skip = req.params.skip || 0;
    var cell_line = req.params.cell || null;
    var pert = req.params.pert || null;
    var dose = req.params.dose || null;
    var duration = req.params.duration || null;
    var gold;
    if (req.params.gold) {
        gold = JSON.parse(String(req.params.gold).toLowerCase());
    } else {
        gold = null;
    }
    lincs.getByPert(cell_line, pert, Number(dose), Number(duration), Number(skip), Number(limit), gold, 
                    function(err, data) {
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
 * @apiParam {numeric} dose dose (unitless)
 * @apiParam {numeric} duration duration (unitless)
 * @apiParam {String} cell cell line used
 * @apiParam {String} method calculation method used, e.g. "zsvc_plate"
 * @apiParam {boolean} gold is this a gold signature score?
 * @apiParam {[String]} gene_ids from lincs
 * @apiParam {[Numeric]} data the scores (one per gene)
 *
 * @apiSuccess {string} Id of created object
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
 * @api {GET} /LINCS/instances/:id Retrieve data document by id 
 * @apiName getdata
 * @apiGroup LINCS
 * @apiDescription Retrieves gene ids, Q2Norm data, and metadata
 *
 * @apiParam {String} id of desired instance.
 *
 * @apiSuccess {string} data Document in JSON format
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * "gene_ids": [
 *     "200814_at",
 *     "222103_at",
 *     "...truncated..."
 *     ],
 * "metadata": {
 *     "bead_batch": "b3",
 *     "bead_revision": "r2",
 *     "bead_set": "dp52,dp53",
 *     "cell_id": "HCC515",
 *     "...truncated..."
 * },
 * "norm_exp": [
 *     9.15469932556152,
 *     9.05399990081787,
 *     "...truncated..."
 *     ]
 *  }
 */
server.get('/LINCS/instances/:id', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.getExpression(req.params.id, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
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
 * @apiParam {[String]} gene_ids from lincs
 * @apiParam {[Numeric]} data the expression data
 *
 * @apiSuccess {string} response response
 * @apiSuccessExample Success-Response: 
 * HTTP/1.1 200 OK
 * {
 * }
 */
server.post('/LINCS/instances', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    if(!checkParams(req.params, ['id', 'gene_ids', 'metadata', 'data', 'type'])) {
        res.send(400, "Creating instance document requires POSTing the following " +
                      "parameters: id, gene_ids, data, metadata, type"); 
    } else {
        var doc = {gene_ids: req.params.gene_ids, 
                   metadata: req.params.metadata,
                   data: req.params.data,
                   type: req.params.type,
                   gold: req.params.gold};
                   console.log(req.params.metadata)
                   
        lincs.saveInstance(req.params.id, doc, function(err, data) {
            if(err) {
                res.send(400, err);
            } else {
                res.send(200, data);
            }
        });
    }
});

/**
 * @api {GET} /LINCS/instances/:id/controls Retrieve control data 
 * @apiName getControls
 * @apiGroup LINCS
 * @apiDescription Retrieves the full data document for each instance on the 
 * same plate as :id whose perturbagen is the appropriate control for that 
 * instance (including time of exposure and cell line). 
 *
 * @apiParam {String} id of instance for which controls are desired.
 *
 * @apiSuccess {string} data Document in JSON format
 * @apiSuccessExample Success-Response (note array): 
 * HTTP/1.1 200 OK
 * {
 * ["gene_ids": [
 *     "200814_at",
 *     "222103_at",
 *     "...truncated..."
 *     ],
 * "metadata": {
 *     "bead_batch": "b3",
 *     "bead_revision": "r2",
 *     "bead_set": "dp52,dp53",
 *     "cell_id": "HCC515",
 *     "...truncated..."
 * },
 * "norm_exp": [
 *     9.15469932556152,
 *     9.05399990081787,
 *     "...truncated..."
 *     ]
 *  },
 *  "...truncated..."
 * ]
 * }
 */
server.get('/LINCS/instances/:id/controls', function(req, res){
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    lincs.instSamePlateVehicles(req.params.id, function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
});

var port = config.port; // should get from config file some day

server.listen(port, function() {
    console.log('\t%s listening at %s', server.name, server.url);
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
