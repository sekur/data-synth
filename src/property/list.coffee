class ListProperty extends (require '../property')
  @set synth: 'list'
  @merge options: [ 'subtype' ]

  constructor: ->
    @constructor.set type: 'array', subtype: (@constructor.get 'type')
    super

  get: -> super.map (x) -> x.get?() ? x

  Meta = require '../meta'
  normalize: ->
    super.map (x) => switch
      when (Meta.instanceof @opts.subtype)
        if x instanceof @opts.subtype then x
        else new @opts.subtype x, this
      else x

  validate: (value) ->
    super and value.every (x) =>
      (not @opts.subtype?) or (typeof x is @opts.subtype) or (x instanceof @opts.subtype)

module.exports = ListProperty
