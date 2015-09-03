Meta = require './meta'
Promise = require 'promise'

class SynthObject extends Meta
  @set synth: 'object'

  @schema = (obj) -> @bind k, v for k, v of obj

  @attr = (type, opts) ->
    class extends (require './property')
      @set type: type
      @merge opts

  @list = (type, opts) ->
    class extends (require './property/list')
      @set type: type
      @merge opts

  @computed  = (func, opts) ->
    class extends (require './property/computed')
      @set func: func
      @merge opts

  # invoke allows you to apply arbitrary function on the Object as a Promise
  invoke: (action, args..., cb) ->
    unless action instanceof Function
      return Promise.reject "cannot invoke without providing 'action' as a function"
      
    new Promise (resolve, reject) =>
      if cb instanceof Function
        action.apply this, args.concat ->
          try resolve cb.apply null, arguments
          catch err then reject err
      else
        try resolve action.apply this, args.concat cb
        catch err then reject err

  get: (keys...) ->
    keys = keys.filter (e) -> !!e
    switch keys.length
      when 1 then return super keys[0]
      when 0 then keys.push k for k, v of @properties when not v.opts?.private
    return unless keys.length
    return keys
      .map (key) => Meta.objectify key, super key
      .reduce ((a, b) -> Meta.copy a, b), {}

  addProperty: (key, property) ->
    if not (@hasProperty key) and property instanceof Meta
      @properties[key] = property
    property
  removeProperty: (key) -> delete @properties[key] if @hasProperty key
  hasProperty: (key) -> @properties.hasOwnProperty key
  everyProperty: (func) -> (func?.call prop, key) for key, prop of @properties

  validate: -> (prop for k, prop of @properties).every (e) -> (not e?.validate?) or e.validate()
  serialize: (opts={}) ->
    opts.format ?= 'json'
    o = switch opts.format
      when 'xml' then ''
      else {}
    @everyProperty (key) ->
      return if @opts?.private
      return unless @serialize instanceof Function

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
