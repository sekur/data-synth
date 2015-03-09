# DATA STORM module

The DATA STORM module is a JS class hierarchy framework that provides
hierarchical grouping representation of models, objects, and
properties for describing relationships and state/config data.

## Basic Usage

```coffeescript
DS = require 'data-storm'

class Song extends DS.Model
  @name: @attr 'string'
  
class MusicLibrary extends DS.Model
  @songs: @hasMany Song

music = new MusicLibrary
music.set 'songs', [ (new Song name: 'November Rain') ]
music.serialize()
```

This module is a meta collection of various class objects that
represent the various data entity constructs.

    module.exports =
      Model:  require './model'
      Object: require './object'
      Property: require './property'
      Action: require './property/action'
      Computed: require './property/computed'
      Relationship: require './property/relationship'
      BelongsTo: require './property/belongsTo'
      HasMany: require './property/HasMany'
      Registry: require './registry'
      Class: require './class'
      Promise: require 'promise'

