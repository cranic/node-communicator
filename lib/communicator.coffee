###
Communicator
###
path = require 'path'
fs = require 'fs'
jstoxml = require 'jstoxml'
async = require 'async'
xml2js = require 'xml2js'
xmlParser = new xml2js.Parser()

class Communicator
    configurator : (obj = new Object) ->
        @folder = obj.folder or  './rpc'
        @endpoint = obj.endpoint or '/api'
        @version = obj.version or '1.0'
        @debug = obj.debug or false

        rpcPath = path.dirname(process.mainModule.filename) + "/#{@folder}"
        rpcPath = path.normalize rpcPath

        @modules = new Object
        read = fs.readdirSync rpcPath
        for module in read
            module = path.basename module, '.js'
            @modules[module] = require rpcPath + "/#{module}"
        @

    response : (res, method, message) ->
        obj = new Object
        obj.error = message.error or false
        obj.message = message.message or  null
        obj.params = message.params or null

        if method == 'json'
            res.header 'content-type', 'application/json'
            response = JSON.stringify obj
        else if method == 'xml'
            if !obj.message
                obj.message = ' '
            if !obj.params
                obj.params = ' '
            if !obj.error
                obj.error = 'false'
            else
                obj.error = 'true'
                
            res.header 'content-type', 'application/xml'
            response = jstoxml.toXML response : obj
        else
            res.header 'content-type', 'application/json'

        res.send response or JSON.stringify obj

    parse : (method, body, callback) ->
        process.nextTick ->
            proceed = (response) ->
                if typeof response == 'object'
                    if Object.keys(response).length != 2 or !response.method or !response.params or response.method.split('.').length != 2
                        callback 'Malformed request.'
                    else
                        response.method = response.method.split '.'
                        callback null, response

            switch method
                when 'json'
                    try
                        response = JSON.parse body
                    catch error
                        callback 'Unable to parse JSON request.'
                    finally
                        proceed response if response

                when 'xml'
                    xmlParser.parseString body, (err, obj) ->
                        if err
                            callback 'Unable to parse XML request.'
                        else
                            proceed obj
                else
                    callback 'Unknown parse method.'

    express : (obj = new Object) ->
        com = require('communicator').configurator obj
        if com.debug
            console.log '[Communicator]  Communicator configured with Express.js, using modules:', '\n', com.modules

        (req, res, next) ->
            if req.url != "#{com.endpoint}/#{com.version}"
                next()
            else
                console.log "[Communicator] Got a hit from #{req.connection.remoteAddress}." if com.debug == true
                req.rawBody = ''
                req.on 'data', (chunck) ->
                    req.rawBody += chunck

                req.on 'end', ->
                    async.series
                        method : (cb) ->
                            if typeof req.headers['content-type'] == 'undefined'
                                method = 'unknown'
                            else if req.headers['content-type'] == 'application/json'
                                method = 'json'
                            else if req.headers['content-type'] == 'application/xml'
                                method = 'xml'
                            else
                                method = 'unknown'
                            cb null, method

                        post : (cb) ->
                            if req.method == 'POST' 
                                post = 'post' 
                            else 
                                post = 'unknown'
                            cb null, post

                        body : (cb) ->
                            if typeof req.headers['content-type'] == 'undefined'
                                method = 'unknown'
                            else if req.headers['content-type'] == 'application/json'
                                method = 'json'
                            else if req.headers['content-type'] == 'application/xml'
                                method = 'xml'
                            else
                                method = 'unknown'
                            
                            com.parse method, req.rawBody, (err, obj) ->
                                if err
                                    cb null, err
                                else
                                    cb null, obj                

                        , (err, result) ->
                            if result.method == 'unknown'
                                com.response res, 'json', 
                                    error : true
                                    message : 'Unsuported or unsettled request header.' 
                                    params :
                                        "content-type" : req.headers['content-type'] or 'unknown'
                            else if result.post == 'unknown' 
                                com.response res, result.method,
                                    error : true
                                    message : 'Unsuported call method.'
                                    params :
                                        "method" : req.method or 'unknown'
                            else if typeof result.body == 'string'
                                com.response res, result.method,
                                    error : true
                                    message : result.body

                            else if typeof com.modules[result.body.method[0]] == 'undefined' or typeof com.modules[result.body.method[0]][result.body.method[1]] == 'undefined'
                                com.response res, result.method,
                                    error : true
                                    message : 'Unknown method or action.'
                                    params : 
                                        method : result.body.method[0] or 'unknown'
                                        action : result.body.method[1] or 'unknown'
                            else
                                com.modules[result.body.method[0]][result.body.method[1]] req, result.body.params, (err, respond) ->
                                    if err
                                        com.response res, result.method,
                                            error : true
                                            message : err.message or 'An error accurred.'
                                            params : err.params or null
                                    else
                                        com.response res, result.method,
                                            error : false
                                            message : respond.message or 'Request succeeded.'
                                            params : respond.params or null

module.exports = new Communicator()
