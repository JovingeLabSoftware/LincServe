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
 * @apiSuccess {string} OK.  Send GET to /LINCS for further documentation.
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
 * @apiSuccessExample {Object} Success-Response: 
 *[ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',
 *  summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },
 *{ id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',
 *  summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]
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
 * @apiSuccessExample {Object} Success-Response: 
 *[ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',
 *  summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },
 *{ id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',
 *  summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]
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
 * @apiSuccessExample {Object} Success-Response: 
 *[ { key: [ 'A375', 'BRD-K73037408', 2.5, 6 ],                                                                                  
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
 */
server.get('LINCS/instances', function(req, res) {
    console.log(req.params)
    req.params = dequote(req.params);
    var limit = req.params.limit || 1000;
    var skip = req.params.skip || 0;
    var cell_line = req.params.cell || null;
    var pert = req.params.pert || null;
    var dose = req.params.dose || null;
    var duration = req.params.duration || null;
    var gold = req.params.gold || null;
    lincs.getByPert(cell_line, pert, Number(dose), Number(duration), Number(skip), Number(limit), gold, 
                    function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
            console.log(data);
        }
    });
});


/**
 * @api {POST} /LINCS/zscores Save zscores to database
 * @apiName setZScores
 * @apiGroup LINCS
 * @apiDescription Saves z-score document to document stre.
 * 
 * @apiParam {String} pert Name of perturbagen.
 * @apiParam {String} cell Name of cell line.  
 * @apiParam {Numeric} dose Dose, without units.  
 * @apiParam {Numeric} duration Duration, without units.  
 * @apiParam {Boolean} gold Is this signature derived from gold instances?  
 * @apiParam {String} type The type of zscore, e.g. "ZSVC_L1000"
 * @apiParam {String[]} gene_ids The ids of the genes in the signature
 * @apiParam {Numberic[]} zscores The scores
 * @apiSuccess {string} cas CAS number
 */
server.post('LINCS/zscores', function(req, res) {
    req.params = dequote(req.params);
    var cell_line = req.params.cell;
    var pert = req.params.pert;
    var dose = req.params.dose;
    var duration = req.params.duration;
    var gene_ids = req.params.gene_ids;
    var zscores = req.params.zscores;
    var type = req.params.type;
    var gold = req.params.gold || false;
    if(!cell_line || !pert || !type || !dose || !duration) {
        res.send(400, "Must specify cell_line, pert, dose, duration, and score type when inserting Z-score document");
    }
    lincs.saveZScores(cell_line, pert, dose, duration, type, gene_ids, zscores, gold,
        function(err, data) {
        if(err) {
            res.send(400, err);
        } else {
            res.send(200, data);
        }
    });
});

                                           
/**
 * @api {GET} /LINCS/:id Retrieve data document by id 
 * @apiName getdata
 * @apiGroup LINCS
 * @apiDescription Retrieves gene ids, Q2Norm data, and metadata
 *
 * @apiParam {String} id of desired instance.
 *
 * @apiSuccess {string} data Document in JSON format
 * @apiSuccessExample {Object} Success-Response: 
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
server.get('/LINCS/:id', function(req, res){
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

//["A375","BRD-K73037408",2.5,6]

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

