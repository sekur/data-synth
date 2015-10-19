Array::equals = (x) ->
  compare = (a, b) ->
    a = a.get() if a?.get instanceof Function
    b = b.get() if b?.get instanceof Function
    (typeof a is typeof b) and switch
      when a instanceof Array then a.equals b
      when a instanceof Object
        res = true
        for k, v of a
          unless compare v, b[k]
            res = false; break
        res
      else a is b
  @length is x.length and @every (e, i) -> compare e, x[i]

Array::unique = (key) ->
  return @ unless @length > 0
  output = {}
  unless key?
    output[@[key]] = @[key] for key in [0...@length]
  else
    for k in [0..@length-1] when typeof @[k] is 'object'
      val = @[k]
      idx = val[key]
      idx ?= val.get? key
      idx ?= k
      #console.log "Array::unique with #{key} as #{idx}"
      continue unless idx?
      output[idx] = val
  (value for key, value of output)

Array::contains = (query) ->
  return false if typeof query isnt "object"
  hit = Object.keys(query).length
  @some (item) ->
    item = item.get() if item.get instanceof Function
    match = 0
    for key, val of query
      match += 1 if item[key] is val
    if match is hit then true else false

Array::where = (query) ->
  return [] if typeof query isnt "object"
  return this unless Object.keys(query).length > 0
  @filter (item) ->
    item = item.get() if item.get instanceof Function
    for key, val of query when val?
      match = switch
        when val instanceof Function then val item[key]
        when val instanceof Array then item[key] in val
        else item[key] is val
      return false unless match
    true # item matched all query params

Array::without = (query) ->
  return this if typeof query isnt "object"
  return this unless Object.keys(query).length > 0
  @filter (item) ->
    item = item.get() if item.get instanceof Function
    for key, val of query when val?
      match = switch
        when val instanceof Function then val item[key]
        when val instanceof Array then item[key] in val
        else item[key] is val
      return true unless match
    false # item matched all query params

Array::pushRecord = (record) ->
  return null if typeof record isnt "object"
  @push record unless @contains(id:record.id)

# Built-in types:
# date, boolean, string, and array

class SynthProperty extends (require './meta')
  @set synth: 'property', config: true, mandatory: false, unique: false, private: false
  @set options: [ 'type', 'subtype', 'key', 'units', 'mandatory',
    'unique', 'private', 'config', 'default', 'normalizer',
    'validator', 'serializer' ]

  constructor: ->
    @opts = @constructor.extract.apply @constructor, @constructor.get 'options'
    @isDirty = false
    super
    @opts.default ?= [] if @opts.type is 'array'
    @value ?= @normalize switch
      when @opts.default instanceof Function then @opts.default.call @parent
      else @opts.default

  get: -> v = super; v?.get?() ? v

  set: (value) ->
    console.assert @opts.type?,
      "cannot set a value to a property without type"
      
    value ?= switch
      when @opts.default instanceof Function then @opts.default.call @parent
      else @opts.default
    cval = @value
    nval = @normalize value

    #console.log "setting #{value} normalized to #{nval}"
    console.assert (@validate nval) is true,
      "unable to validate passed in '#{nval}' as type '#{@opts.type}' with errors: #{nval?.errors}"

    @isDirty = switch
      when not cval? and nval? then true
      when @opts.type is 'array' then not (nval.equals cval)
      when cval is nval then false
      else true

    @lastValue ?= cval if @isDirty
    @value = nval

  normalize: (value, opts=@opts) ->
    if opts.normalizer instanceof Function
      return opts.normalizer.call this, value
    return unless value?
    
    switch
      when (SynthProperty.instanceof opts.type) and not (value instanceof opts.type)
        new opts.type value, this
      when opts.type instanceof Function
        opts.type.call this, value
      when opts.type is 'string' and typeof value isnt 'string'
        "#{value}"
      when opts.type is 'date' and typeof value is 'string'
        new Date value
      when opts.type is 'boolean' and typeof value is 'string'
        value is 'true'
      when opts.type is 'number' and typeof value is 'string'
        (Number) value
      when opts.type is 'array'
        #console.log "normalize array... with key: #{opts.key} [#{opts.unique}]"
        unless value instanceof Array
          value = if value? then [ value ] else []
        value = value.filter (e) -> e? and !!e
        value = value.unique opts.key if opts.unique is true
        value
      else
        value

  validate: (value=@value, opts=@opts) ->
    switch
      when not value?
        opts.mandatory is false
      when opts.validator instanceof Function
        opts.validator.call this, value
      when SynthProperty.instanceof opts.type
        value instanceof opts.type
      when opts.type instanceof Function
        if value.validate?
          value.validate()
        else
          value is (opts.type.call this, value)
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
  diff:     -> @get() if @isDirty
  save:     -> @isDirty = false; @lastValue = undefined
  rollback: -> if @isDirty then @value = @lastValue; @save()

module.exports = SynthProperty
