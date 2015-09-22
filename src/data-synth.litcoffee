# DATA SYNTH module

The DATA SYNTH module is a JS class hierarchy framework that provides
hierarchical grouping representation of modules, models, objects, and
properties for describing relationships and state/config data.

    class Synth extends (require './meta')
      constructor: (source, hook) ->
        unless Synth.instanceof @constructor
          # construction via ()
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
        super

    exports = module.exports = Synth

Container Data Entities

    exports.Store        = Synth (require './store')
    exports.Model        = Synth (require './model')
    exports.Object       = Synth (require './object')

Property Data Entities
    
    exports.Property     = Synth (require './property')
    exports.Computed     = Synth (require './property/computed')
    exports.List         = Synth (require './property/list')
    exports.Relationship = Synth (require './property/relationship')
    exports.BelongsTo    = Synth (require './property/belongsTo')
    exports.HasMany      = Synth (require './property/hasMany')

Other Data Entities

    exports.Action       = Synth (require './action')
    exports.Controller   = Synth (require './controller')
    exports.Registry     = Synth (require './registry')
    exports.Meta         = Synth (require './meta')
