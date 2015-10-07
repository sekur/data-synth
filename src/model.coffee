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

  serialize: (opts={}) ->
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

  contains: (key) -> (@access key)

uuid = require 'node-uuid'

class SynthModel extends (require './object')
  @set synth: 'model', name: undefined, records: {}

  @instanceof = (x) ->
    return false unless x?
    x instanceof this or x instanceof this.__super__?.constructor

  @mixin (require 'events').EventEmitter

  @belongsTo = (model, opts) ->
    class extends (require './property/belongsTo')
      @set model: model
      @merge opts

  @hasMany = (model, opts) ->
    class extends (require './property/hasMany')
      @set model: model
      @merge opts

  @action = (func, opts) ->
    class extends (require './property/action')
      @set func: func
      @merge opts

  constructor: ->
    # register a default 'save' and 'destroy' handler event (can be overridden)
    @attach 'save',    (resolve, reject) -> return resolve this
    @attach 'destroy', (resolve, reject) -> return resolve this
    super
    @name = @meta 'name'
    console.assert @name?,
      "Model must have a 'name' metadata specified for construction"
    @id = uuid.v4() # every model instance has a unique ID

  fetch: (key) -> @meta "records.#{key}"

  find:  (query) -> (v for k, v of (@meta 'records')).where query
  match: (query) ->
    for k, v of query
      x = (@access k)?.normalize (@get k)
      x = "#{x}" if typeof x is 'boolean' and typeof v is 'string'
      return false unless x is v
    return true

  toString: -> "#{@meta 'name'}:#{@id}"

  set: ->
    # before setting ANY new value, keep track of any changes
    # only after successful 'save' the transaction logs are cleared
    super

  # This is a convenince wrapper to invoke internal 'save' method
  save: ->
    @invoke 'save', arguments...
    .then (res) =>
      @id = (@get 'id') ? @id
      @set 'id', @id
      @clearDirty()
      @constructor.set "records.#{@id}", this
      return res

  destroy: ->
    @invoke 'destroy', arguments...
    .then (res) =>
      #record.destroy() for record in @get '_bindings'
      @constructor.delete "records.#{@id}"
      return res

  rollback: ->
    # TBD


  # The below `invoke` for the `SynthModel` is a magical
  # one-liner... Figuring out how it works is an exercise left to the
  # reader. :-)
  # invoke: (event, args...) ->
  #   Promise.all (@listeners event).map (f) => super ([f].concat args)... 

  RelationshipProperty = (require './property/relationship')

  getRelationships: (kind) ->
    @everyProperty (key) -> this if this instanceof RelationshipProperty
    .filter (x) -> x? and (not kind? or kind is (x.constructor.get 'kind'))

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
      (@access 'children').push record.save()

module.exports = SynthModel
