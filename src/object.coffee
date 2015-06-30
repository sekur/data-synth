
class StormObject extends (require './meta')
  @set storm: 'object'

  @attr = (type, opts) ->
    class extends (require './property')
      @set type: type
      @merge opts

  @computed  = (func, opts) ->
    class extends (require './property/computed')
      @set func: func
      @merge opts

  constructor: (data, @container) ->
    for key, val of @constructor when key isnt 'constructor' and @constructor.instanceof val
      @constructor.bind key, val
    super data

  keys: -> Object.keys @properties

  addProperty: (key, property) ->
    if not (@hasProperty key) and property instanceof Meta
      @properties[key] = property
    property
  removeProperty: (key) -> delete @properties[key] if @hasProperty key
  hasProperty: (key) -> @properties.hasOwnProperty key
  everyProperty: (func) -> (func?.call prop, key) for key, prop of @properties

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
