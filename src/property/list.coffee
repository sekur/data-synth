Meta = require '../meta'

class ListProperty extends (require '../property')
  @set synth: 'list', unique: true, 'max-elements': undefined, 'min-elements': 0
  @merge options: [ 'max-elements', 'min-elements', 'ordered-by' ]

  constructor: ->
    unless (@constructor.get 'type') is 'array'
      @constructor.set type: 'array', subtype: (@constructor.get 'type')
    super
    @opts['max-elements'] ?= 'unbounded'

  get: (key) ->
    list = (super null).map (x) -> x.get?() ? x
    return list unless key? and key isnt '*'

    mkey = @opts.key
    for item in list
      ikey = item[mkey]
      match = switch typeof ikey
        when 'number'  then ikey is (Number) key
        when 'string'  then ikey is (String) key
        when 'boolean' then ikey is (Boolean) key
        else ikey is key
      return item if match is true
    undefined

  match: (query={}) ->
    super
      .map (x) -> x.get?() ? x
      .where query

  access: (key) ->
    return @value unless key? and key isnt '*'
    mkey = @opts.key
    res = []
    for item in @value
      val = (item.get? key) ? item[key]
      if val?
        res.push val
        continue

      ikey = (item.get? mkey) ? item[mkey]
      match = switch typeof ikey
        when 'number'  then ikey is (Number) key
        when 'string'  then ikey is (String) key
        when 'boolean' then ikey is (Boolean) key
        else ikey is key
      return item if match is true
    return if res.length > 0 then res else undefined
    
  push: ->
    items = @normalize [].concat arguments...
    unless @validate items
      errors = items.reduce ((a,b) -> a.concat b.errors... ), []
      throw new Error "[list:push] validation errors: #{errors}"
    @set @value.concat items
    return items

  remove: (keys...) ->
    # XXX - need to convert passed-in keys to the format of the key values...
    # keys.map (x) => @opts.subtype.get 
    
    query = Meta.objectify @opts.key, [].concat keys...
    @set @value.without query

  normalize: ->
    # TODO: this one can use some refactoring...
    super.map (x) => switch
      when (Meta.instanceof @opts.subtype)
        switch
          when (x instanceof @opts.subtype) then x
          when (@opts.subtype.get 'synth') is 'model'
            if @opts.subtype.instanceof x then x
            else
              store = @seek synth: 'store'
              return unless store?
              [ key, value ] = switch
                when x instanceof Meta
                  [ (@opts.subtype.get 'name'), x.get() ]
                when @opts.subtype.modelof x
                  [ (@opts.subtype.get 'name'), x ]
                when x instanceof Object
                  for name, data of x then break
                  [ name, data ]
              record = store.create key, value
              record?.save()
              record
          else new @opts.subtype x, this
      when @opts.subtype instanceof Function
        @opts.subtype x
      else x

  validate: (value=@value) ->
    max = (Number) @opts['max-elements'] unless @opts['max-elements'] is 'unbounded'
    min = (Number) @opts['min-elements']
    bounds = (x) -> unless max? then x >= min else min <= x <= max

    super and (bounds value.length) and value.every (x) =>
      switch
        when not @opts.subtype? then true
        when Meta.instanceof @opts.subtype
          check = x instanceof @opts.subtype
          check = @opts.subtype.instanceof x unless check
          check and (if x.validate? then x.validate() else true)
        when @opts.subtype instanceof Function
          x is (@opts.subtype x)
        else
          typeof x is @opts.subtype

  diff: ->
    return super unless Meta.instanceof @opts.subtype
    diff = (@value.map (x) =>
      changes = x.diff?()
      # attach the 'key' for this item for diff so we know the
      # identifier for the object that got changed
      changes?[@opts.key] = x.get @opts.key
      changes
    ).filter (e) -> e?
    return null unless diff.length > 0
    diff

  save: ->
    return super unless Meta.instanceof @opts.subtype
    @value.forEach (e) -> e.save?()

module.exports = ListProperty
