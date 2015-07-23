# DATA SYNTH module

The DATA SYNTH module is a JS class hierarchy framework that provides
hierarchical grouping representation of modules, models, objects, and
properties for describing relationships and state/config data.

    class Synth extends (require './meta')

      constructor: (source, hook) ->
        # construction via ()
        unless Synth.instanceof @constructor
          unless (source.constructor is arguments.callee or source.__super__?.constructor is arguments.callee)
            # we layer a new anonymous class with constructor that
            # returns an extension of the 'source' class
            res = class extends source
              constructor: (input, func=hook) ->
                unless source.instanceof @constructor
                  return class extends source
                    @name: source.name
                    @merge input
                    @configure func
                super
          else
            res = class extends source
                @name: source.name
                @configure hook
          return res
          
        # construction via new
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
    exports.Interface    = Synth (require './interface')
    exports.Controller   = Synth (require './controller')
    exports.Registry     = Synth (require './registry')
    exports.Meta         = (require './meta')
