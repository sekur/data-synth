# DATA SYNTH module

The DATA SYNTH module is a JS class hierarchy framework that provides
hierarchical grouping representation of modules, models, objects, and
properties for describing relationships and state/config data.

    class Synth extends (require './meta')
      @instantiate: (constructor) ->
        @constructor is constructor or @constructor.__super__?.constructor is constructor

      constructor: (source, hook) ->
        # construction via ()
        unless Synth.instanceof @constructor
          unless source.constructor is arguments.callee or source.__super__?.constructor is arguments.callee
            #console.log "enabling Synth on #{source.name}"
            return (input) ->
              class extends source
                @merge input
                @configure hook

          return class extends source
            @configure hook

        super

    exports = module.exports = Synth

Container Data Entities

    exports.Module       = Synth (require './module')
    exports.Model        = Synth (require './model')
    exports.Object       = Synth (require './object')

Property Data Entities
    
    exports.Property     = Synth (require './property')
    exports.List         = Synth (require './property/list')
    exports.Computed     = Synth (require './property/computed')
    exports.Relationship = Synth (require './property/relationship')
    exports.BelongsTo    = Synth (require './property/belongsTo')
    exports.HasMany      = Synth (require './property/hasMany')

Other Data Entities

    #exports.Store
    #exports.View
    #exports.Action       = require './property/action'
    exports.Controller   = Synth (require './controller')
    exports.Registry     = Synth (require './registry')
    exports.Meta         = (require './meta')
