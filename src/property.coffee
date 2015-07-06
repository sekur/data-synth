assert = require 'assert'

class SynthProperty extends (require './meta')
  @set synth: 'property', required: false, unique: false
  @set options: [
    'type', 'required', 'unique', 'defaultValue', 'normalizer', 'validator', 'serializer'
  ]

  constructor: (value, @obj) ->
    super
    
    assert @obj instanceof (require './object'),
        "cannot instantiate a new property without containing object reference"
        
    @opts = @constructor.extract.apply @constructor, @constructor.get 'options'
    @isDirty = false
    @set value

  set: (value) ->
    value ?= switch
      when typeof @opts.defaultValue is 'function' then @opts.defaultValue.call @obj
      else @opts.defaultValue
    cval = @get()
    nval = @normalize value

    assert (@validate nval) is true,
      "unable to validate passed in (#{value}) as (#{nval}) for setting on this property"

    @isDirty = switch
      when not cval? and nval? then true
      when @opts.type is 'array' then not cval.equals nval
      when cval is nval then false
      else true

    super nval

  normalize: (value=@get()) ->
    switch
      when @opts.normalizer instanceof Function
        @opts.normalizer.call @obj, value
      when @opts.type is 'date' and typeof value is 'string'
        new Date value
      when @opts.type is 'array'
        unless value instanceof Array
          value = if value? then [ value ] else []
        value = value.filter (e) -> e? and !!e
        value = value.unique() if @opts.unique is true
        value
      else
        value

  validate: (value=@get()) ->
    switch
      when @opts.validator instanceof Function
        @opts.validator.call @obj, value
      when not value?
        @opts.required is false
      else switch @opts.type
        when 'string' or 'number' or 'boolean' or 'object'
          typeof value is @opts.type
        when 'date'
          value instanceof Date
        when 'array'
          value instanceof Array
        else
          true

  serialize: (value=@get(), opts={}) ->
    opts.format ?= 'json'
    if @opts.serializer instanceof Function
      @opts.serializer.call @obj, value, opts
    else
      value

module.exports = SynthProperty
