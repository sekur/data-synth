StormClass = require '../class'
assert = require 'assert'

class RelationshipProperty extends (require '../property')
  @set storm: 'relation'

  kind: null

  constructor: (@model, opts={}, obj) ->
    assert typeof @model?.constructor is 'function',
        "cannot register a new relationship without proper model class"
    assert obj instanceof StormClass,
        "cannot register a new relationship without containing obj defined"

    type = switch @kind
        when 'belongsTo' then 'string'
        when 'hasMany' then 'array'

    opts.unique = true if @kind is 'hasMany'
    super type, opts, obj

  #serialize: -> super @get()

module.exports = RelationshipProperty
