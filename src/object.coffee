Meta = require './meta'

class SynthObject extends Meta
  @set synth: 'object', __schema__: {}, default: {}

  @schema = (obj) -> @merge '__schema__', obj

  @attr = (type, opts) ->
    class extends (require './property')
      @set type: type
      @merge opts

  @computed  = (func, opts) ->
    class extends (require './property/computed')
      @set func: func
      @merge opts

  constructor: ->
    @constructor.bind k, v for k, v of (@constructor.get '__schema__')
    super

  get: (keys...) ->
    keys = keys.filter (e) -> !!e
    switch keys.length
      when 1 then return super keys[0]
      when 0 then keys.push k for k, v of @properties when not v.opts?.private
    return unless keys.length
    return keys
      .map (key) => Meta.objectify key, super key
      .reduce ((a, b) -> Meta.copy a, b), {}

  set: -> super; @value ?= {}
        
  addProperty: (key, property) ->
    if not (@hasProperty key) and property instanceof Meta
      @properties[key] = property
    property
  removeProperty: (key) -> delete @properties[key] if @hasProperty key
  hasProperty: (key) -> @properties.hasOwnProperty key
  everyProperty: (func) -> (func?.call prop, key) for key, prop of @properties

  validate: -> (@everyProperty (key) -> name: key, isValid: @validate()).filter (e) -> e.isValid is false

  serialize: (opts={}) ->
    opts.format ?= 'json'
    o = switch opts.format
      when 'xml' then ''
      else {}
    @everyProperty (key) ->
      return if @opts?.private
      unless @serialize instanceof Function
        console.warn "#{key} does not have serialize function"
      switch opts.format
        when 'json' then o[key] = @serialize? opts
        when 'xml'  then o += "<#{key}>" + (@serialize? opts) + "</#{key}>"
    return o

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

module.exports = SynthObject
