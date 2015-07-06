# DATA SYNTH module

The DATA SYNTH module is a JS class hierarchy framework that provides
hierarchical grouping representation of models, objects, and
properties for describing relationships and state/config data.

This module is a meta collection of various class objects that
represent the various data entity constructs.

    exports = module.exports = require './module'

Container-based Data Entities

    #exports.View = require './view'
    exports.Controller   = require './controller'
    exports.Model        = require './model'
    exports.Object       = require './object'
    exports.Registry     = require './registry'
    exports.Meta         = require './meta'

Property-based Data Entities
    
    exports.Property     = require './property'
    exports.Array        = require './property'
    exports.Action       = require './property/action'
    exports.Computed     = require './property/computed'
    exports.Relationship = require './property/relationship'
    exports.BelongsTo    = require './property/belongsTo'
    exports.HasMany      = require './property/hasMany'
