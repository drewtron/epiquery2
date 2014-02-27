#! /usr/bin/env coffee

WebSocket     = require 'ws'
EventEmitter  = require('events').EventEmitter
_             = require 'underscore'
clients       = require '../../src/clients/EpiClient.coffee'
optimist      = require 'optimist'

EpiBufferingClient = clients.EpiBufferingClient
EpiClient = clients.EpiClient

args = optimist.argv

template = args.template
connectionName = args.connection
data = JSON.parse(args.data || "{}")
repeatCount = Number(args.repeat || 1)
SERVER=process.env.EPI_TEST_SERVER || "localhost"
PORT=process.env.PORT || 8080

# capture our events so we can disply the results in a deterministic order
c = new EpiClient "ws://localhost:8080/sockjs/websocket"
c.rowOutput = []
c.dataOutput = []

exitWhenDone = _.after(repeatCount, () ->
  console.log c.beginqueryOutput
  console.log c.endqueryOutput

  for row in c.rowOutput
    console.log row
  for row in c.dataOutput
    console.log row
  process.exit 0
)
c.on 'beginquery', (msg) ->
  c.beginqueryOutput = 'beginquery' + JSON.stringify msg
c.on 'row', (msg) ->
  c.rowOutput.push 'row' + JSON.stringify msg
c.on 'data', (msg) ->
  c.rowOutput.push 'data' + JSON.stringify msg
c.on 'endquery', (msg) ->
  c.endqueryOutput = 'endquery' + JSON.stringify msg
  exitWhenDone()

if repeatCount is 1
  c.query(connectionName, template, data, "basicSocketQueryId")
else
  c.query(connectionName, template, data, "basicSocketQueryId#{num}") for num in [1..repeatCount]