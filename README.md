# data-storm

  STORM data models that represent hierarchical data structures with
  dynamic getter/setter interfaces and persistence layer for
  [node](http://nodejs.org).

  [![NPM Version][npm-image]][npm-url]
  [![NPM Downloads][downloads-image]][downloads-url]

## Installation
```bash
$ npm install data-storm
```

## Literate Coffeescript Documentation

* [DATA STORM](src/data-storm.litcoffee)

### STORM Data Entities
* [STORM Model](src/model.litcoffee)
* [STORM Object](src/object.litcoffee)
* [STORM Class](src/class.litcoffee)

### STORM Properties
* [STORM Property](src/property.litcoffee)
* [STORM Array](src/property/array.litcoffee)
* [STORM Action](src/property/action.litcoffee)
* [STORM Relationship](src/property/relationship.litcoffee)
* [STORM BelongsTo (one-to-one)](src/property/belongsTo.litcoffee)
* [STORM HasMany (one-to-many)](src/property/hasMany.litcoffee) 

## License
  [MIT](LICENSE)

[npm-image]: https://img.shields.io/npm/v/data-storm.svg
[npm-url]: https://npmjs.org/package/data-storm
[downloads-image]: https://img.shields.io/npm/dm/data-storm.svg
[downloads-url]: https://npmjs.org/package/data-storm
