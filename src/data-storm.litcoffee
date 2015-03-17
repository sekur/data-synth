# DATA STORM module

The DATA STORM module is a JS class hierarchy framework that provides
hierarchical grouping representation of models, objects, and
properties for describing relationships and state/config data.

This module is a meta collection of various class objects that
represent the various data entity constructs.

    module.exports =
      Model: require './model'
      Object: require './object'
      Property: require './property'
      Array: require './property'
      Action: require './property/action'
      Computed: require './property/computed'
      Relationship: require './property/relationship'
      BelongsTo: require './property/belongsTo'
      HasMany: require './property/hasMany'
      Registry: require './registry'
      Class: require './class'
      Promise: require 'promise'

