StormClass = require './class'
StormProperty = require './property'
ComputedProperty = require './property/computed'

class StormObject extends StormClass
  @set storm: 'object'

  @attr = (type, opts) ->
    class extends StormProperty
      @set type: type, opts: opts

  @computed  = (func, opts) ->
    class extends ComputedProperty
      @set type: func, opts: opts

  constructor: (data, @opts={}, @container) ->
    @_properties = {}
    for key, StormConstructor of @constructor when key isnt 'constructor' and StormConstructor?.meta?.storm?
      StormType = switch (StormConstructor.get 'storm')
        when 'object' then StormConstructor.get 'data'
        else StormConstructor.get 'type'

      @addProperty key, (new StormConstructor StormType, (StormConstructor.get 'opts'), this)

    # initialize all properties to defaultValues
    @everyProperty (key) -> @set undefined, skipValidation: true
    (@set data, skipValidation: true) if data?

  keys: -> Object.keys @_properties

  addProperty: (key, property) ->
    if not (@hasProperty key) and property instanceof StormClass
      @_properties[key] = property
    property

  removeProperty: (key) -> delete @_properties[key] if @hasProperty key
  hasProperty: (key) -> @_properties.hasOwnProperty key

  ###*
  # `getProperty` supports retrieving property based on composite key such as:
  # 'hello.world.bye'
  #
  # Since this routine is the primary function for get/set operations,
  # you can also use it to specify nested path during those operations.
  ###
  getProperty: (key) ->
    return unless key?
    composite = key?.split '.'
    key = composite.shift()
    prop = @_properties[key] if @hasProperty key
    for key in composite
      return unless prop?
      prop = prop.getProperty? key
    prop

  get: (keys...) ->
    result = {}
    switch
      when keys.length is 0
        @everyProperty (key) -> result[key] = @get()
      when keys.length is 1
        result = (@getProperty keys[0])?.get()
      else
        result[key] = (@getProperty key)?.get() for key in keys
    result

  ###*
  # `set` is used to place values on matching StormProperty
  # instances. Accepts an object of key/values
  #
  # obj.set hello:'world'
  #
  # { hello: 'world' }
  #
  # obj.set test:'a', sample:'b'
  #
  # obj.set 'test.nested.param':'a', sample:'b'
  #
  # also takes in `opts` as an optional param object to override
  # validations and other special considerations during the `set`
  # execution.
  ###
  set: (obj, opts) ->
    return unless obj instanceof Object
    ((@getProperty key)?.set value, opts) for key, value of obj
    this # make it chainable

  everyProperty: (func) -> (func?.call prop, key) for key, prop of @_properties

  validate: -> (@everyProperty (key) -> name: key, isValid: @validate()).filter (e) -> e.isValid is false

  serialize: (format='json') ->
    o = switch format
      when 'json' then {}
      else ''
    @everyProperty (key) ->
      switch format
        when 'json' then o[key] = @serialize format
        when 'xml' then o += "<#{key}>" + (@serialize format) + "</#{key}>"
    o

  clearDirty: -> @everyProperty -> @isDirty = false
  dirtyProperties: (keys) -> (@everyProperty (key) -> @isDirty ? key).filter (x) ->
    if keys? then x? and x in keys else x?
  isDirty: (keys) ->
    keys = [ keys ] if keys? and keys not instanceof Array
    (@dirtyProperties keys).length > 0

    ### for future optimization reference
    dirty = @dirtyProperties().join ' '
    keys.some (prop) -> ~dirty.indexOf prop
    ###

module.exports = StormObject
