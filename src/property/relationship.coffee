assert = require 'assert'

class RelationshipProperty extends (require '../property')
  @set synth: 'relation', embedded: false, 'require-instance': false
  @merge options: [ 'model', 'kind', 'embedded', 'require-instance' ]

  constructor: ->
    super

    @model = switch
      when @opts.model instanceof Function then @opts.model
      when typeof @opts.model is 'string' then "noooo"

    assert @model instanceof Function,
        "cannot instantiate a new relationship without proper model class"
        
    @opts.type = switch @opts.kind
      when 'belongsTo' then 'string'
      when 'hasMany' then 'array'

  fetch: (key) ->
    return unless key?
    [ name, key ] = key.split ':'
    unless key?
      key = name
      name = @model.get 'name'
    (@model::fetch key) ? (@seek synth: 'store')?.find name, key

module.exports = RelationshipProperty
