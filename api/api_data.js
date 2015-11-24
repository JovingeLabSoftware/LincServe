define({ "api": [
  {
    "type": "GET",
    "url": "/LINCS/instances",
    "title": "Retrieve instance ids by perturbagen or range",
    "name": "getInstance",
    "group": "LINCS",
    "description": "<p>Retrieves instance ids based on range of perturbagen or index.  Note: if perturbagen is specified, cell line must be specified (because this function queries a view with compound key).  Similarly, if dose and duration are specified, cell line and perturbagen must be also.</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "pert",
            "description": "<p>Name of perturbagen.  Optional (but see above).</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "cell",
            "description": "<p>Name of cell line.  Optional (but see above).</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "dose",
            "description": "<p>Dose, without units.  Optional (but see above).</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "duration",
            "description": "<p>Duration, without units.  Optional (but see above).</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "instances",
            "description": "<p>Instance ids  in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "[ { key: [ 'A375', 'BRD-K73037408', 2.5, 6 ],                                                                                  \n   value:                                                                                                                     \n    { distil_id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A08',                                                                   \n      vehicle: 'DMSO' },                                                                                                      \n   id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A08' },                                                                           \n { key: [ 'A375', 'BRD-K73037408', 2.5, 6 ],                                                                                  \n   value:                                                                                                                     \n    { distil_id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A16',                                                                   \n      vehicle: 'DMSO' },                                                                                                      \n   id: 'PCLB001_A375_6H_X1_F2B6_DUO52HI53LO:A16' },   \n\n    \"...truncated...\"\n]",
          "type": "Object"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "GET",
    "url": "/LINCS/:id",
    "title": "Retrieve data document by id",
    "name": "getdata",
    "group": "LINCS",
    "description": "<p>Retrieves gene ids, Q2Norm data, and metadata</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "id",
            "description": "<p>of desired instance.</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>Document in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "{\n\"gene_ids\": [\n    \"200814_at\",\n    \"222103_at\",\n    \"...truncated...\"\n    ],\n\"metadata\": {\n    \"bead_batch\": \"b3\",\n    \"bead_revision\": \"r2\",\n    \"bead_set\": \"dp52,dp53\",\n    \"cell_id\": \"HCC515\",\n    \"...truncated...\"\n},\n\"norm_exp\": [\n    9.15469932556152,\n    9.05399990081787,\n    \"...truncated...\"\n    ]\n }",
          "type": "Object"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "get",
    "url": "/LINCS/nidrange",
    "title": "Request range of numerical index.",
    "description": "<p>Remember that the numerical indices are used for rapid paging/chunking.  They are NOT necessarily uniqe, NOT contiguous, and NOT in any sort of order.  But they are FAST.</p> ",
    "name": "nixrange",
    "group": "LINCS",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>integer</p> ",
            "optional": false,
            "field": "first",
            "description": "<p>Smallest index</p> "
          },
          {
            "group": "Success 200",
            "type": "<p>integer</p> ",
            "optional": false,
            "field": "last",
            "description": "<p>Largest index</p> "
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "POST",
    "url": "/LINCS/zscores",
    "title": "Save zscores to database",
    "name": "setZScores",
    "group": "LINCS",
    "description": "<p>Saves z-score document to document stre.</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "pert",
            "description": "<p>Name of perturbagen.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "cell",
            "description": "<p>Name of cell line.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "dose",
            "description": "<p>Dose, without units.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "duration",
            "description": "<p>Duration, without units.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Boolean</p> ",
            "optional": false,
            "field": "gold",
            "description": "<p>Is this signature derived from gold instances?</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "type",
            "description": "<p>The type of zscore, e.g. &quot;ZSVC_L1000&quot;</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": false,
            "field": "gene_ids",
            "description": "<p>The ids of the genes in the signature</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numberic[]</p> ",
            "optional": false,
            "field": "zscores",
            "description": "<p>The scores</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "cas",
            "description": "<p>CAS number</p> "
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "GET",
    "url": "/LINCS/summaries",
    "title": "Request summary docs by document index (1..N)",
    "name": "summaries",
    "group": "LINCS",
    "description": "<p>Remember that the numerical ids are used for rapid paging/chunking.  They are NOT necessarily uniqe, NOT contiguous, and NOT in any sort of order.  But they are FAST.</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "skip",
            "description": "<p>Starting numerical index.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "limit",
            "description": "<p>Ending numerical index.</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "summaries",
            "description": "<p>Summary docs in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "[ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',\n summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },\n{ id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',\n summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]",
          "type": "Object"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "GET",
    "url": "/LINCS/summaries/nid",
    "title": "Request summary docs by numerical id range",
    "name": "summaries_nid",
    "group": "LINCS",
    "description": "<p>Remember that the numerical ids are used for rapid paging/chunking.  They are NOT necessarily uniqe, NOT contiguous, and NOT in any sort of order.  But they are FAST.</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "first",
            "description": "<p>Starting numerical index.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "last",
            "description": "<p>Ending numerical index.</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "summaries",
            "description": "<p>Summary docs in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "[ { id: 'CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05',\n summary: { pert_desc: 'EI-328', pert_type: 'trt_cp', cell_id: 'VCAP' } },\n{ id: 'KDC003_VCAP_120H_X3_B5_DUO52HI53LO:M08',\n summary: { pert_desc: 'SOX5', pert_type: 'trt_sh', cell_id: 'VCAP' } } ]",
          "type": "Object"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "get",
    "url": "/",
    "title": "Root.  Verify server up and receive useful advice.",
    "name": "Root",
    "group": "Root",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "OK.",
            "description": "<p>Send GET to /LINCS for further documentation.</p> "
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "Root"
  },
  {
    "type": "get",
    "url": "/LINCS",
    "title": "Get some documentation on endpoints.",
    "name": "Root",
    "group": "Root",
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "response",
            "description": "<p>Some useful information.</p> "
          }
        ]
      }
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "Root"
  }
] });