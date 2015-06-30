assert = require 'assert'

class ComputedProperty extends (require '../property')
  @set storm: 'computed', cache: 0
  @merge options: [ 'cache', 'func' ]

  constructor: ->
    super

    assert @opts.func instanceof Function,
      "cannot instantiate a new ComputedProperty without a function"
    @cachedOn = new Date() if @opts.cache > 0

  get: ->
    unless @value? and (@opts.cache > 0 and (new Date() - @cachedOn)/1000 < @opts.cache)
      # XXX - handle @opts.async is 'true' in the future (return a Promise)
      @set (@opts.func.call @obj)
      @cachedOn = new Date() if @opts.cache > 0
    super

module.exports = ComputedProperty
