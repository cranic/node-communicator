node-communicator
=================

Communicator aims to be an intermediate between client and server using the old  and good RPC over HTTP method.
Currently it's handling XML and JSON request.

#### Main features

* Modular: each file in a folder is a method, and every exported function in that file is an action.
* Versioned endpoints: you can have multiple endpoints with different versions, ex: /api/0.1 and /api/2.1
* Multiple protocols: currently we have support for JSON and XML, but more protocols like YAML can be implemented in the future.

#### Installation

1 - Install by npm: `npm install communicator`    
2 - Create a folder for handling the methods:

    |- myapp
       |- app.js
       |- rpc <-- created folder

3 - Create a file in that folder, the name of the file will be the name of the method.

    |- myapp
       |- app.js
       |- rpc
          |- user.js <-- created file

4 - Export functions inside that file, every exported function will be an action.

user.js

    exports.add = function(req, params, callback){
        // do your user adding logic here ;)
        // we pass null to the first callback parameter 
        // indicating that there was no error
        callback(null, {
            "message" : "User added!",
            "params" : {
                "username" : "foobar"
            }
        });
    }

    exports.remove = function(req, params, callback){
        // this time we will return an error
        callback({
            "message" : "Oops, we got an error here...",
            "params" : {
                "username" : "foobar"
            }
        });
    }

    exports.echo = function(req, params, callback){
        // A simple echo on the params
        callback(null, {
            "message" : "Echo system.",
            "params" : params
        });
    }

5 - Configure Express:

app.js

    var express = require('express');
    var app = express();
    var com = require('communicator');

    app.use(com.express({
        debug : true, //enabling debug messages, default: false
        endpoint : '/api', //change de endpoint of the api, default: '/api'
        version : '1.0' //change the endpoint version, default: '1.0'
    }));

    app.get('/', function(req, res){
      res.send('Hello World');
    });

    app.listen(80);

Now we are good to go, spin up you `app.js` and start making your requests:

    POST http://localhost/api/1.0
    Content-Type: application/json

    {
        "method" : "user.echo", 
        "params" : {
            "foo" : "bar"
        }
    }

    ---> RESPONSE
    Content-Type: application/json

    {
        "error": false,
        "message": "Echo system.",
        "params": {
            "lol": "kel"
        }
    }

    POST http://localhost/api/1.0
    Content-Type: application/xml

    <request>
        <method>user.add</method>
        <params>
            <foo>bar</foo>
        </params>
    </request>

    ---> RESPONSE
    Content-Type: application/xml
    
    <response>
        <error>false</error>
        <message>User added!</message>
        <params>
            <username>foobar</username>
        </params>
    </response>

You can easy build an jQuery extension for handling requests :)

#### License

The MIT License (MIT) Copyright (c) 2012 Cranic Tecnologia e Informática LTDA

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or 
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE