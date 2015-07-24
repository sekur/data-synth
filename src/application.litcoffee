# SynthApplication

The `SynthApplication` represents the runtime app

    #ModelRegistry = require './registry/model'

    SynthModule = (require './module')

    class SynthApplication extends SynthModule
      @set synth: 'application'  #, registry: new ModelRegistry

      # default properties schema
      #logfile:   @attr 'string', default: @computed -> "/tmp/#{@constructor.name}-#{@get('id')}.log"
      @loglevel: @attr 'string', default: 'info'
      @datadir:  @attr 'string', default: '/tmp'

      # Application can have collection of other modules
      @modules: @hasMany SynthModule, private: true

      @run = (process, opts) ->
        argv = require('minimist')(process.argv.slice(2), opts)
        if argv.h?
          console.log """
            #{@get 'name'} [opts] [command] [target]

            [opts]
            -h view this help
            -l level:logfile (e.g. info:/some/file/path, )
              log level: trace, debug, info (default), warn, error
              when not set, will run in 'debug' level to console
            -c address:port (e.g. remote-address:12345)
            -s address:port (e.g. localhost:5000)

            [command]
            build - create a new module specified in [target]

            [target]
            directory - build contents inside target directory (such as .)
            filename  - build according to specified build file (e.g. synth.json)
          """
          return

        config =
          port:    argv.p ? 8080
          logfile: argv.l ? "/tmp/synth.log"
          loglevel: if argv.z in [ 'trace','debug','info','warn','error' ] then argv.z else 'info'

        [ command, target ] = argv._

        instance = new this config
        switch command
          when 'build'
            target ?= '.'
            instance.invoke command, target
            .then (output) ->

  #-------------------------------
  # main usage functions

  # opens the store according to the provided requestor access constraints
  # this should be subclassed for view control based on requestor
  open: (requestor) -> new View @, requestor

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


module.exports = SynthModule
