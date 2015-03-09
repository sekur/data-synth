assert = require 'assert'

class ComputedProperty extends (require '../property')
  @set storm: 'computed'

  kind: 'computed'
  ###*
  # @property func
  # @default null
  ###
  @func = -> null

  constructor: (@func, opts={}, obj) ->
    console.log 'computed'
    console.log @func
    assert typeof @func is 'function',
      "cannot register a new ComputedProperty without a function"
    type = opts.type ? 'computed'
    super type, opts, obj
    @cache = opts.cache ? 0
    @cachedOn = new Date() if @cache > 0

  isCachedValid: -> @cache > 0 and (new Date() - @cachedOn)/1000 < @cache

  get: ->
    unless @value? and @isCachedValid()
      # XXX - handle @opts.async is 'true' in the future (return a Promise)
      @set (@func.call @obj)
      @cachedOn = new Date() if @cache > 0
    super

  serialize: -> super @get()

module.exports = ComputedProperty
