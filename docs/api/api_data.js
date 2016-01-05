define({ "api": [
  {
    "type": "POST",
    "url": "/LINCS/pert",
    "title": "Create a perturbation data document",
    "name": "createPerturbation",
    "group": "LINCS",
    "description": "<p>Creates a data document for a particular perturbation &amp; calculation method</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "perturbagen",
            "description": "<p>name of perturbagen</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "dose",
            "description": "<p>dose (unitless)</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric</p> ",
            "optional": false,
            "field": "duration",
            "description": "<p>duration (unitless)</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "cell",
            "description": "<p>cell line used</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "method",
            "description": "<p>calculation method used, e.g. &quot;zsvc_plate&quot;</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Boolean</p> ",
            "optional": false,
            "field": "gold",
            "description": "<p>is this a gold signature score?</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": false,
            "field": "gene_ids",
            "description": "<p>from lincs</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric[]</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>the scores (one per gene)</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "Id",
            "description": "<p>of created object</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 201 Created\n{\n id: 1\n}",
          "type": "json"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "POST",
    "url": "/LINCS/instances/distil_id",
    "title": "data by distil_id (multi)",
    "name": "distilIdsData",
    "group": "LINCS",
    "description": "<p>Fetch data for given instances by distil_id.  We use POST here because keys are long and could quickly exceed GET query string limits. The same data can be achieved with the /LINCS/instances GET endpoint using the 'q' parameter, but that may fail with large numbers of distil_ids due to query string length limits imposed by many clients.</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>string[]</p> ",
            "optional": false,
            "field": "ids",
            "description": "<p>distilIds of instances</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>string[]</p> ",
            "optional": false,
            "field": "fields",
            "description": "<p>fields to return (defaults to all data)</p> "
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example usage:",
        "content": "curl -d '{\"ids\": [\"CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05\", \\\n      \"CPC014_VCAP_6H_X2_F1B3_DUO52HI53LO:P05\"]}' \\\n      localhost:8080/LINCS/instances/distil_id \\\n      -H \"Content-Type: application/json\"",
        "type": "curl"
      }
    ],
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>Object</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>docs in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 200 OK\nContent-Type: application/json\n[  \n{\n   \"data\": { ... }\n   \"gene_ids\": { ... }\n   \"metadata\": { ... },\n   \"id\": \"312240\"\n } \n... // truncated\n]",
          "type": "json"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "GET",
    "url": "/LINCS/instances/:id",
    "title": "Request instance by id",
    "name": "instanceById",
    "group": "LINCS",
    "description": "<p>Fetch data for a given instance by id</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "id",
            "description": "<p>Id of instance</p> "
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example usage:",
        "content": "curl localhost:8080/LINCS/instances/2",
        "type": "curl"
      }
    ],
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>Object</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>data docs in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 200 OK\nContent-Type: application/json\n{\n  \"data\": { ... },\n  \"metadata\": { ... },\n  \"timestamp\": \"2015-12-18 03:52:52\",\n  \"id\": \"1230884\"\n}",
          "type": "json"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "GET",
    "url": "/LINCS/instances",
    "title": "Query instances",
    "name": "instanceQuery",
    "group": "LINCS",
    "description": "<p>Fetch data for instances matching query.  Either ids or q should be specified</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": true,
            "field": "ids",
            "description": "<p>Optional explicit list of primary ids</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": true,
            "field": "q",
            "description": "<p>Optional query in form of field: value pairs, as in: q={&quot;pert_desc&quot;: &quot;celecoxib&quot;, &quot;pert_type&quot;: &quot;trt_cp&quot;}.<br> Note that fields are assumed to be in metadata slot. Querying outside the metadata is not possible.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": true,
            "field": "f",
            "description": "<p>Optional list of fields to return, e.g. [metadata.pert_desc, gene_ids] Note that parent field must be explicitly declared (e.g. metadata), so that top level slots (data, gene_ids) can be requested and returned.</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "s",
            "description": "<p>Number of records to skip (for paging)</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Number</p> ",
            "optional": false,
            "field": "l",
            "description": "<p>Number of records to return (limit)</p> "
          }
        ]
      }
    },
    "examples": [
      {
        "title": "Example usage:",
        "content": "curl -G \"http://localhost:8080/LINCS/instances\" --data-urlencode \"ids=[1,2,3]\" \\\n   --data-urlencode f='[\"metadata.pert_type\"]'\ncurl -G \"http://localhost:8082/LINCS/instances\" --data-urlencode q='{\"pert_desc\": \"celecoxib\"}' \\\n   --data-urlencode f='[\"metadata.pert_type\"]' --data l=10 --data s=10",
        "type": "curl"
      }
    ],
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>Object</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>data docs in JSON format</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 200 OK\nContent-Type: application/json\n{\n  [\n    {\n      \"id\":\"1\",\n      \"pert_type\":\"trt_cp\"\n      },\n      {\n         \"id\":\"2\",\n         \"pert_type\":\"trt_cp\"\n          \n      },\n      {\n        \"id\":\"3\",\n        \"pert_type\":\"trt_cp\"\n      }\n    ]\n}",
          "type": "json"
        }
      ]
    },
    "version": "0.0.0",
    "filename": "bin/app.js",
    "groupTitle": "LINCS"
  },
  {
    "type": "POST",
    "url": "/LINCS/instances",
    "title": "Save instance data to server",
    "name": "postInstance",
    "group": "LINCS",
    "description": "<p>Stores instance (e.g. level 2 data) on the server. Do NOT use this endpoint to save calculated scores (use /LINCS/pert for that).</p> ",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "id",
            "description": "<p>desired id (key) of document</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "metadata",
            "description": "<p>JSON from lincs</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "type",
            "description": "<p>Type of data, e.g. &quot;q2norm&quot;</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>String[]</p> ",
            "optional": false,
            "field": "gene_ids",
            "description": "<p>from lincs</p> "
          },
          {
            "group": "Parameter",
            "type": "<p>Numeric[]</p> ",
            "optional": false,
            "field": "data",
            "description": "<p>the expression data</p> "
          }
        ]
      }
    },
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>String</p> ",
            "optional": false,
            "field": "response",
            "description": "<p>response</p> "
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 200 OK\n{\n}",
          "type": "json"
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
    "examples": [
      {
        "title": "Example usage:",
        "content": "curl http://localhost:8080/",
        "type": "curl"
      }
    ],
    "success": {
      "fields": {
        "Success 200": [
          {
            "group": "Success 200",
            "type": "<p>string</p> ",
            "optional": false,
            "field": "response",
            "description": ""
          }
        ]
      },
      "examples": [
        {
          "title": "Success-Response: ",
          "content": "HTTP/1.1 200 OK\nOK.  Send GET to /LINCS for further documentation.",
          "type": "json"
        }
      ]
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