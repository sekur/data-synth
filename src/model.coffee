Registry = require './registry'

class ModelRegistryProperty extends Registry.Property

  constructor: (@model, opts, obj) -> super 'object', opts, obj

  match: (query, keys=false) ->
    switch
      when query instanceof Array then super
      when query instanceof Object
        for k, v of @get() when v.match query
          if keys then k else v
      else
        super

  serialize: (format='json') ->
    ids: Object.keys(@value)
    numRecords: Object.keys(@value).length

class ModelRegistry extends Registry

  @Property = ModelRegistryProperty

  register: (model, opts) ->
    # may not need this...
    # model.meta ?= name: model.name
    # model.meta.name ?= model.name
    super model.meta.name, new ModelRegistryProperty model, opts, this

  add: (records...) ->
    obj = {}
    obj[record.get('id')] = record for record in records when record instanceof Model
    super record.constructor.meta.name, obj

  remove: (records...) ->
    query = (record.get('id') for record in records when record instanceof Model)
    super record.constructor.meta.name, query

  contains: (key) -> (@getProperty key)


class SynthModel extends (require './object')
  @set synth: 'model'

  @belongsTo = (model, opts) ->
    class extends (require './property/belongsTo')
      @set type: model, opts: opts

  @hasMany = (model, opts) ->
    class extends (require './property/hasMany')
      @set type: model, opts: opts

  @action = (func, opts) ->
    class extends (require './property/action')
      @set func: func, opts: opts

  # internal tracking of bound model records
  @_bindings: @hasMany SynthModel, private: true

  # this is a PRIVATE shared prototype singleton ModelRegistry
  # instance visible across ALL model instances (intentionally
  # undocumented)
  #
  # It is publicly accessible via the DataSynth class
  #_models: new ModelRegistry

  constructor: ->
    super
    @_models.register @constructor
    @_models.add this

  get: ->
      @set 'accessedOn', new Date
      super

  fetch: (id) -> @_models.find @constructor.meta.name, id

  getRelationships: (kind) ->
      @everyProperty (key) -> this if this instanceof RelationshipProperty
      .filter (x) -> x? and (not kind? or kind is x.kind)

  ###*
  # `bind` subjugates passed in records to be bound to the lifespan of
  # the current model record.
  #
  # When this current model record is destroyed, all bound dependents
  # will also be destroyed.
  ###
  bind: (records...) ->
    for record in records
      continue unless record? and record instanceof SynthModel
      (@getProperty '_bindings').push record.save()

  match: (query) ->
      for k, v of query
          x = (@getProperty k)?.normalize (@get k)
          x = "#{x}" if typeof x is 'boolean' and typeof v is 'string'
          return false unless x is v
      return true

  save: ->
    # XXX - a bit ugly at the moment...
    # console.log 'SAVING:'
    isValid = @validate()
    # console.log isValid
    if isValid.length is 0
        (@set 'modifiedOn', new Date) if @isDirty()
        @clearDirty()
        @_models.add this
        this
    else
        null

  destroy: ->
      record.destroy() for record in @get '_bindings'
      @_models.remove this

  Promise = require 'promise'
  invoke: (action, args...) ->
    new Promise (resolve, reject) =>
      try
        unless action instanceof Function
          action = (@getProperty action)?.exec
        resolve (action?.apply this, args)
      catch err
        reject err

module.exports = SynthModel
