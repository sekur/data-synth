class ListProperty extends (require '../property')
  @set synth: 'list', unique: true, 'max-elements': 'unbounded', 'min-elements': 0
  @merge options: [ 'max-elements', 'min-elements', 'ordered-by' ]

  constructor: ->
    unless (@constructor.get 'type') is 'array'
      @constructor.set type: 'array', subtype: (@constructor.get 'type')
    super

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
    
  push: ->
    items = @normalize [].concat arguments...
    unless @validate items
      errors = items.reduce ((a,b) -> a.concat b.errors... ), []
      throw new Error "[list:push] validation errors: #{errors}"
    @set @value.concat items
    return items

  remove: (keys...) ->
    query = ListProperty.objectify @opts.key, [].concat keys...
    @set @value.without query

  Meta = require '../meta'
  normalize: ->
    # TODO: this one can use some refactoring...
    super.map (x) => switch
      when (Meta.instanceof @opts.subtype)
        switch
          when (x instanceof @opts.subtype) then x
          when (@opts.subtype.get 'synth') is 'model'
            if @opts.subtype.instanceof x then x
            else
              record = switch
                when x instanceof Meta
                  new @opts.subtype x.get(), this
                when @opts.subtype.modelof x
                  new @opts.subtype x, this
                when x instanceof Object
                  for name, data of x then break
                  (@seek synth: 'store')?.create name, data
              record.save()
              record
          else new @opts.subtype x, this
      else x

  validate: (value=@value) ->
    max = (Number) @opts['max-elements'] unless @opts['max-elements'] is 'unbounded'
    min = (Number) @opts['min-elements']
    bounds = (x) -> unless max? then x >= min else min <= x <= max

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
