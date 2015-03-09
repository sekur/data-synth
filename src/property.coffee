StormClass = require './class'

class PropertyValidationError extends Error

assert = require 'assert'
  
class StormProperty extends StormClass
  @set storm: 'property'

  kind: 'attr'

  constructor: (@type, @opts={}, @obj) ->
    assert @obj instanceof (require './object'),
        "cannot register a new property without a reference to an object it belongs to"

    @opts.required ?= false
    @opts.unique ?= false

    ###*
    # @property value
    ###
    @value = undefined
    ###*
    # @property isDirty
    # @default false
    ###
    @isDirty = false

  get: -> if @value instanceof StormProperty then @value.get() else @value

  set: (value, opts={}) ->
    # console.log "setting #{@constructor.name} of type: #{@type} with:"
    # console.log value
    ArrayEquals = (a,b) -> a.length is b.length and a.every (elem, i) -> elem is b[i]

    value ?= switch
      when typeof @opts.defaultValue is 'function' then @opts.defaultValue.call @obj
      else @opts.defaultValue

    cval = @value
    nval = @normalize value

    # console.log "set() normalized new value: #{nval}"
    # console.log nval

    if nval instanceof Array and nval.length > 0
      nval = (nval.filter (e) -> e?)
      nval = nval.unique() if @opts.unique is true

    # if nval instanceof StormProperty
    #   opts.skipValidation = true

    # console.log "set() validating new value: #{nval}"
    # console.log nval

    unless opts.skipValidation is true or @validate nval
        return new PropertyValidationError nval

    @isDirty = switch
      when not cval? and nval? then true
      when @type is 'array' then not ArrayEquals cval, nval
      when cval is nval then false
      else true
    @value = nval if @isDirty is true

    #console.log "set() isDirty: #{@isDirty} and value: #{@value}"
    this

  validate: (value=@value) ->
    # execute custom validator if available
    if typeof @opts.validator is 'function'
      return (@opts.validator.call @obj, value)

    unless value?
      return (@opts.required is false)

    if value instanceof StormProperty
      value = value.get()

    switch @type
      when 'string' or 'number' or 'boolean' or 'object'
        typeof value is @type
      when 'date'
        value instanceof Date
      when 'array'
        value instanceof Array
      else
        true

  normalize: (value) ->
    switch
      when value instanceof Object and typeof value.stormify is 'function'
        # a special case, returns new form of StormProperty
        value.stormify.call @obj
      when @type is 'date' and typeof value is 'string'
        new Date value
      when @type is 'array' and not (value instanceof Array)
        if value? then [ value ] else []
      else
        value

  serialize: (format='json') ->
    switch
      when typeof @opts.serializer is 'function'
        @opts.serializer.call @obj, @value, format
      when @value instanceof StormProperty
        @value.serialize format
      else
        @value

module.exports = StormProperty
