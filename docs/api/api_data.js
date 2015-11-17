define({ "api": [
  {
    "type": "get",
    "url": "/LINCS/nixrange",
    "title": "Request range of numerical index",
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
  }
] });