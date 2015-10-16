Meta = require './meta'

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

  get: (keys...) ->
    keys = keys.filter (e) -> !!e
    switch keys.length
      when 1 then return super keys[0]
      when 0 then keys.push k for k, v of @properties when not v.opts?.private
    return unless keys.length
    return keys
      .map (key) => Meta.objectify key, super key
      .reduce ((a, b) -> Meta.copy a, b), {}

  every: (func) -> (func?.call prop, key) for key, prop of @properties

  validate: ->
    @errors = []
    for k, prop of @properties
      continue unless prop?.validate?
      @errors.push k unless prop.validate()
    if @errors.length > 0
      console.warn "validation errors: #{@errors}"
    @errors.length is 0

  serialize: (opts={}) ->
    (@every (k) -> (Meta.objectify k, @serialize? opts) unless @opts?.private)
    .reduce ((a, b) -> Meta.copy a, b), {}

  diff: ->
    changes = (@every (key) ->
      diff = @diff?()
      Meta.objectify key, diff if diff?
    ).reduce ((a,b) -> Meta.copy a, b), {}
    return null unless Object.keys(changes).length > 0
    changes

  save:     -> @every -> @save?()
  rollback: -> @every -> @rollback?()

  ## for future optimization reference
  # dirty = @dirtyProperties().join ' '
  # keys.some (prop) -> ~dirty.indexOf prop

module.exports = SynthObject
