
class CircularBuffer
  constructor: (@size=10) ->
    @buffer = []
    @curPos = 0

  store: (element) =>
    @buffer[@curPos++] = element
    @curPos = 0 if @curPos >= @size
    undefined

  getEntries: () =>
    entries = (item for item in @buffer)

module.exports.CircularBuffer = CircularBuffer

