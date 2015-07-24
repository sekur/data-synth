# data-synth

  Dynamic data model synthesizer that can represent hierarchical data
  structures with dynamic getter/setter interfaces, data normalizers,
  validators, serializers with flexible class extensions using Meta
  data class objects for [node](http://nodejs.org).

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

## Advanced Usage

For advanced usage examples, be sure to check out
[yangforge](http://github.com/saintkepha/yangforge) where `data-synth`
is utilized for metacompilation of YANG schemas to auto-generate
runtime data model instances, which in turn enables auto-generation of
various interfaces (such as CLI, HTTP/REST/JSON, etc.)

## Literate Coffeescript Documentation

* [Synthesizer](src/data-synth.litcoffee)

### Container Entities
* [Store](src/store.litcoffee)
* [Model](src/model.coffee)
* [Object](src/object.litcoffee)

### Property Entities
* [Property](src/property.coffee)
* [Computed](src/property/computed.coffee)
* [List](src/property/list.litcoffee)
* [Relationship](src/property/relationship.coffee)
* [BelongsTo (one-to-one)](src/property/belongsTo.coffee)
* [HasMany (one-to-many)](src/property/hasMany.coffee) 

### Other Entities
* [Interface](src/interface.coffee)
* [Controller](src/controller.litcoffee)
* [Registry](src/registry.coffee)
* [Meta](src/meta.litcoffee)

## License
  [MIT](LICENSE)

[npm-image]: https://img.shields.io/npm/v/data-synth.svg
[npm-url]: https://npmjs.org/package/data-synth
[downloads-image]: https://img.shields.io/npm/dm/data-synth.svg
[downloads-url]: https://npmjs.org/package/data-synth
