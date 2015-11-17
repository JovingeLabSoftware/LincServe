define({ "api": [
  {
    "type": "get",
    "url": "/LINCS/nixrange",
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
    "url": "/LINCS/summaries",
    "title": "Request summary docs by numerical index range",
    "name": "summaries",
    "group": "LINCS",
    "description": "<p>Remember that the numerical indices are used for rapid paging/chunking.  They are NOT necessarily uniqe, NOT contiguous, and NOT in any sort of order.  But they are FAST.</p> ",
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
      }
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