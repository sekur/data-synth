# DataStore

The `DataStore` represents the primary container construct for managing various `DataModels`.

    ModelRegistry = require './registry/model'

    class DataStore extends (require './model')
      @set storm: 'store', registry: new ModelRegistry
      @include (require 'events').EventEmitter

      # Storm default properties schema
      #logfile:   @attr 'string', defaultValue: @computed -> "/tmp/#{@constructor.name}-#{@get('id')}.log"
      @loglevel: @attr 'string', defaultValue: 'info'
      @datadir:  @attr 'string', defaultValue: '/tmp'

      # DataStore can have collection of other stores
      @stores: @hasMany DataStore, private: true

      # DataStorm auto-computed properties
      @models: @computed (-> (@constructor.get 'registry').serialize() )

The below `register` for DataStore accepts one or more models and adds
to internal `ModelRegistry` instance.

      register: (models...) ->
        (@constructor.get 'registry').register model for model in models

PUBLIC access methods for working directly with PRIVATE _models registry

      create: (type, data) -> null
      find:   (type, query) -> @_models.find type, query
      update: (type, id, data) -> null
      delete: (type, query) -> model.destroy() for model in (@find type, query)

      contains: (key) ->
        prop = @getProperty key
        prop if prop instanceof StormModel.Registry.Property

      infuse: (opts) ->
        console.log "using: #{opts?.source}"

  #-------------------------------
  # main usage functions

  # opens the store according to the provided requestor access constraints
  # this should be subclassed for view control based on requestor
  open: (requestor) -> new StormView @, requestor

  # register callback for being called on specific event against a collection
  #
  when: (collection, event, callback) ->
      entity = @contains collection
      assert entity? and entity.registry? and event in ['added','updated','removed'] and callback?, "must specify valid collection with event and callback to be notified"
      _store = @
      entity.registry.once 'ready', -> @on event, (args...) -> process.nextTick -> callback.apply _store, args

  commit: (record) ->
      return unless record instanceof DataStoreModel

      @log.debug method:"commit", record: record?.id

      registry = @entities[record.name]?.registry
      assert registry?, "cannot commit '#{record.name}' into store which doesn't contain the collection"

      action = switch
          when record.isDestroy
              registry.remove record.id
              'removed'
          when not record.isSaved
              exists = record.id? and registry.get(record.id)?
              assert not exists, "cannot commit a new record '#{record.name}' into the store using pre-existing ID: #{record.id}"
              registry.add record.id, record
              'added'
          when record.isDirty()
              record.changed = true
              registry.update record.id, record
              delete record.changed
              'updated'

      if action?
          # may be high traffic events, should listen only sparingly
          @emit 'commit', [ action, record.name, record.id ]
          @log.info method:"commit", id:record.id, "#{action} '%s' on the store registry", record.constructor.name


module.exports = DataStorm
