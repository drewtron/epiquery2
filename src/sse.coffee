log     = require 'simplog'
_       = require 'underscore'

# this is used to create a unique identifier for each client created
# since numbers can be really, really big in v8 and node is single
# threaded in its processing of app code, ther's nothing at all special
# needed for this
CLIENT_COUNTER=0

CONNECTED_CLIENTS={}

class Client
  # id is an optional parameter, it's only here to facilitate testing
  constructor: (@req, @res, @id=null) ->
    if not @id
      @id = "#{CLIENT_COUNTER++}#{process.pid}"
    @attach()

  sendData: (data) =>
    @res.write "data: #{data}\n\n"

  sendEvent: (name, data) =>
    @res.write "event: #{name}\n"
    if data and (typeof(data) is "string")
      @res.write "data: #{data}\n"
    else if data
      @res.write "data: #{JSON.stringify data}\n"
    else
      # no data
      @res.write "data:\n"
    @res.write "\n"

  attach: () =>
    @req.socket.setTimeout(Infinity)
    @res.writeHead 200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
    @res.write('\n')

    # this is how we'll hook the close of the request so that we can do
    # any cleanup of our
    registerClose = (clientId, req) ->
      req.on "close", () ->
        log.debug "close event raised for #{clientId}"
        delete CONNECTED_CLIENTS[clientId]
        num = 0
        _.each CONNECTED_CLIENTS, () -> num++
        log.debug "Num connectedClients connected: #{num}"

    CONNECTED_CLIENTS[@id] = this
    registerClose @id, @req

    @sendEvent("id_assign", @id)
    log.debug "attached client: #{@id}"

  close: () =>
    @res.end()


module.exports.Client = Client
module.exports.connectedClients = CONNECTED_CLIENTS
module.exports.getConnectedClientById = (id) -> CONNECTED_CLIENTS[id]
