assert = require 'assert'

class RelationshipProperty extends (require '../property')
  @set synth: 'relation', embedded: false
  @merge options: [ 'model', 'kind', 'embedded' ]

  constructor: ->
    super

    assert @opts.model instanceof Function,
        "cannot instantiate a new relationship without proper model class"
        
    @opts.type ?= switch @opts.kind
      when 'belongsTo' then 'string'
      when 'hasMany' then 'array'

    @model = @opts.model

module.exports = RelationshipProperty
