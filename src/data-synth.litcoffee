# DATA SYNTH module

The DATA SYNTH module is a JS class hierarchy framework that provides
hierarchical grouping representation of modules, models, objects, and
properties for describing relationships and state/config data.

    createSynthesizer = ->
      console.log "should do something..."

    exports = module.exports = createSynthesizer

Container Data Entities

    exports.Module       = require './module'
    exports.Model        = require './model'
    exports.Object       = require './object'

Property Data Entities
    
    exports.Property     = require './property'
    exports.Array        = require './property'
    exports.Action       = require './property/action'
    exports.Computed     = require './property/computed'
    exports.Relationship = require './property/relationship'
    exports.BelongsTo    = require './property/belongsTo'
    exports.HasMany      = require './property/hasMany'

Other Data Entities

    #exports.Store
    #exports.View
    exports.Controller   = require './controller'
    exports.Registry     = require './registry'
    exports.Meta         = require './meta'
