# data-synth

  Dynamic data model synthesizer that can represent hierarchical data
  structures with dynamic getter/setter interfaces and persistence
  layer for [node](http://nodejs.org).

  [![NPM Version][npm-image]][npm-url]
  [![NPM Downloads][downloads-image]][downloads-url]

## Installation

```bash
$ npm install data-synth
```

## Basic Usage

```coffeescript
DS = require 'data-synth'

class Song extends DS.Model
  @name: @attr 'string'
  
class MusicLibrary extends DS.Model
  @songs: @hasMany Song

music = new MusicLibrary
music.set 'songs', [ (new Song name: 'November Rain') ]
music.serialize()
```

## Literate Coffeescript Documentation

* [Main Module](src/data-synth.litcoffee)

### Container Entities
* [Model](src/model.litcoffee)
* [Object](src/object.litcoffee)
* [Meta](src/meta.litcoffee)

### Property Entities
* [Property](src/property.litcoffee)
* [Array](src/property/array.litcoffee)
* [Action](src/property/action.litcoffee)
* [Relationship](src/property/relationship.litcoffee)
* [BelongsTo (one-to-one)](src/property/belongsTo.litcoffee)
* [HasMany (one-to-many)](src/property/hasMany.litcoffee) 

## License
  [MIT](LICENSE)

[npm-image]: https://img.shields.io/npm/v/data-synth.svg
[npm-url]: https://npmjs.org/package/data-synth
[downloads-image]: https://img.shields.io/npm/dm/data-synth.svg
[downloads-url]: https://npmjs.org/package/data-synth
