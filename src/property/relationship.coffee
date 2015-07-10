assert = require 'assert'

class RelationshipProperty extends (require '../property')
  @set synth: 'relation', embedded: false
  @merge options: [ 'model', 'kind', 'embedded' ]

  constructor: ->
    super

    @model = switch
      when @opts.model instanceof Function then @opts.model
      when typeof @opts.model is 'string' then "noooo"

    assert @model instanceof Function,
        "cannot instantiate a new relationship without proper model class"
        
    @opts.type ?= switch @opts.kind
      when 'belongsTo' then 'string'
      when 'hasMany' then 'array'

module.exports = RelationshipProperty
