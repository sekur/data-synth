Array::equals = (x) -> @length is x.length and @every (e, i) -> e is x[i]

Array::unique = ->
   return @ unless @length > 0
   output = {}
   for key in [0..@length-1]
     val = @[key]
     switch
         when typeof val is 'object' and val.id?
             output[val.id] = val
         else
             output[val] = val
   #output[@[key]] = @[key] for key in [0...@length]
   value for key, value of output

Array::contains = (query) ->
   return false if typeof query isnt "object"
   hit = Object.keys(query).length
   @some (item) ->
       match = 0
       for key, val of query
           match += 1 if item[key] is val
       if match is hit then true else false

Array::where = (query) ->
   return [] if typeof query isnt "object"
   hit = Object.keys(query).length
   @filter (item) ->
       match = 0
       for key, val of query
           match += 1 if item[key] is val
       if match is hit then true else false

Array::without = (query) ->
   return @ if typeof query isnt "object"
   @filter (item) ->
       for key,val of query
           return true unless item[key] is val
       false # item matched all query params

Array::pushRecord = (record) ->
   return null if typeof record isnt "object"
   @push record unless @contains(id:record.id)


class SynthProperty extends (require './meta')
  @set synth: 'property', config: true, required: false, unique: false, private: false
  @set options: [
    'type', 'units', 'required', 'unique', 'private', 'config', 'default', 'normalizer', 'validator', 'serializer'
  ]

  constructor: ->
    @opts = @constructor.extract.apply @constructor, @constructor.get 'options'
    @isDirty = false
    
    super

    console.assert @container?,
        "cannot instantiate a new property without containing object reference"

  set: (value) ->
    value ?= switch
      when typeof @opts.default is 'function' then @opts.default.call @container
      else @opts.default
    cval = @value
    nval = @normalize value

    console.log "setting #{value} normalized to #{nval}"

    console.assert @isConstructing or (@validate nval) is true,
      "unable to validate passed in '#{nval}' as '#{@opts.type}' for setting on this property"

    @isDirty = switch
      when not cval? and nval? then true
      when @opts.type is 'array' then not nval.equals cval
      when cval is nval then false
      else true
    @value = nval

  normalize: (value) ->
    switch
      when @opts.normalizer instanceof Function
        @opts.normalizer.call @container, value
      when @opts.type is 'date' and typeof value is 'string'
        new Date value
      when @opts.type is 'boolean' and typeof value is 'string'
        value is 'true'
      when @opts.type is 'array'
        unless value instanceof Array
          value = if value? then [ value ] else []
        value = value.filter (e) -> e? and !!e
        value = value.unique() if @opts.unique is true
        value
      else
        value

  validate: (value) ->
    switch
      when @opts.validator instanceof Function
        @opts.validator.call @container, value
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

  serialize: (opts={}) ->
    value=@get()
    opts.format ?= 'json'
    if @opts.serializer instanceof Function
      @opts.serializer.call @container, value, opts
    else
      value

module.exports = SynthProperty
