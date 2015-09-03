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
   return this unless hit > 0
   @filter (item) ->
     match = 0
     for key, val of query
       match += 1 if item[key] is val
     if match is hit then true else false

Array::without = (query) ->
   return this if typeof query isnt "object"
   @filter (item) ->
     for key, val of query
       match = switch
         when val instanceof Array then item[key] in val
         else item[key] is val
       return true unless match
     false # item matched all query params

Array::pushRecord = (record) ->
   return null if typeof record isnt "object"
   @push record unless @contains(id:record.id)

#
# Built-in types:
# date, boolean, string, array, and mixed

class SynthProperty extends (require './meta')
  @set synth: 'property', config: true, required: false, unique: false, private: false
  @set options: [
    'type', 'types', 'units', 'required', 'unique', 'private', 'config', 'default',
    'normalizer', 'validator', 'serializer'
  ]

  constructor: ->
    @opts = @constructor.extract.apply @constructor, @constructor.get 'options'
    @isDirty = false
    super
    @opts.default ?= [] if @opts.type is 'array'
    @value ?= (@opts.default?.call? this) ? @opts.default

    # XXX - do we *really* need this assertion?
    console.assert @parent?,
      "cannot instantiate a new '#{@opts.type}' property without containing object reference"

    console.assert (@opts.type isnt 'mixed') or (@opts.types? and @opts.types.length > 0),
      "cannot instantiate a new 'mixed' property without 'types' array defined"

  get: -> v = super; v?.get?() ? v

  set: (value) ->
    console.assert @opts.type?,
      "cannot set a value to a property without type"
      
    value ?= (@opts.default?.call? this) ? @opts.default
    cval = @value

    if @opts.type is 'mixed'
      for type in @opts.types
        try
          nval = @normalize value, type: type
          @activeType = type
          break
        catch e
    else
      nval = @normalize value

    #console.log "setting #{value} normalized to #{nval}"
    console.assert (@validate nval) is true,
      "unable to validate passed in '#{nval}' as '#{@opts.type}' for setting on this property"

    @isDirty = switch
      when not cval? and nval? then true
      when @opts.type is 'array' then not nval.equals cval
      when cval is nval then false
      else true
    @value = nval

  normalize: (value, opts=@opts) ->
    if opts.normalizer instanceof Function
      return opts.normalizer.call this, value
    return unless value?
    
    switch
      when opts.type instanceof Function and not (value instanceof opts.type)
        new opts.type value, this
      when opts.type is 'string' and typeof value isnt 'string'
        "#{value}"
      when opts.type is 'date' and typeof value is 'string'
        new Date value
      when opts.type is 'boolean' and typeof value is 'string'
        value is 'true'
      when opts.type is 'number' and typeof value is 'string'
        (Number) value
      when opts.type is 'array'
        unless value instanceof Array
          value = if value? then [ value ] else []
        value = value.filter (e) -> e? and !!e
        value = value.unique() if opts.unique is true
        value
      else
        value

  validate: (value=@value, opts=@opts) ->
    switch
      when not value?
        opts.required is false
      when opts.validator instanceof Function
        opts.validator.call this, value
      when opts.type instanceof Function
        value instanceof opts.type
      else switch opts.type
        when 'string', 'number', 'boolean', 'object'
          typeof value is opts.type
        when 'date'
          value instanceof Date
        when 'array'
          value instanceof Array
        else true

  serialize: (opts={}) ->
    value=@get()
    opts.format ?= 'json'
    if @opts.serializer instanceof Function
      @opts.serializer.call this, value, opts
    else switch @opts.type
      when 'array'
        value.map (e) -> switch
          when e.serialize instanceof Function then e.serialize opts
          else e
      else
        value

module.exports = SynthProperty
