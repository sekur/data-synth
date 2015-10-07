class ListProperty extends (require '../property')
  @set synth: 'list', unique: true, 'max-elements': 'unbounded', 'min-elements': 0
  @merge options: [ 'max-elements', 'min-elements', 'ordered-by' ]

  constructor: ->
    unless (@constructor.get 'type') is 'array'
      @constructor.set type: 'array', subtype: (@constructor.get 'type')
    super

    @opts.max = (Number) @opts['max-elements'] unless @opts['max-elements'] is 'unbounded'
    @opts.min = (Number) @opts['min-elements']

  get: (key) ->
    list = (super null).map (x) -> x.get?() ? x
    return list unless key?
    mkey = @opts.key
    for item in list when key is item[mkey]
      return item
    undefined

  match: (query={}) ->
    super
      .map (x) -> x.get?() ? x
      .where query

  access: (key) ->
    mkey = @opts.key
    for item in @value
      check = (item.get? mkey) ? item[mkey]
      if key is check
        return item
    undefined
    
  push: -> @set @value.concat arguments...

  remove: (keys...) ->
    query = ListProperty.objectify @opts.key, [].concat keys...
    @set @value.without query

  Meta = require '../meta'
  normalize: ->
    super.map (x) => switch
      when (Meta.instanceof @opts.subtype)
        switch
          when (x instanceof @opts.subtype) then x
          when (@opts.subtype.get 'synth') is 'model'
            switch
              when @opts.subtype.instanceof x then x
              when x instanceof Meta
                new @opts.subtype x.get(), this
              when @opts.subtype.modelof x
                new @opts.subtype x, this
              when x instanceof Object
                for name, data of x
                  res = (@seek synth: 'store')?.create name, data
                  break;
                res
          else new @opts.subtype x, this
      else x

  validate: (value=@value) ->
    bounds = (x) =>
      unless @opts.max?
        x >= @opts.min
      else
        @opts.min <= x <= @opts.max

    super and (bounds value.length) and value.every (x) =>
      switch
        when not @opts.subtype? then true
        when @opts.subtype instanceof Function
          check = x instanceof @opts.subtype
          check = @opts.subtype.instanceof x unless check
          check and (if x.validate? then x.validate() else true)
        else
          typeof x is @opts.subtype

module.exports = ListProperty
