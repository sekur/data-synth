class ListProperty extends (require '../property')
  @set synth: 'list'
  @merge options: [ 'subtype', 'key', 'ordered-by' ]

  constructor: ->
    unless (@constructor.get 'type') is 'array'
      @constructor.set type: 'array', subtype: (@constructor.get 'type')
    super

  get: (query={}) ->
    super
      .map (x) -> x.get?() ? x
      .where query

  push: ->
    list = @get()
    Array::push.apply list, arguments
    @set list

  Meta = require '../meta'
  normalize: ->
    super.map (x) => switch
      when (Meta.instanceof @opts.subtype)
        if x instanceof @opts.subtype then x
        else new @opts.subtype x, this
      else x

  validate: (value) ->
    isClass = @opts.subtype instanceof Function
    super and value.every (x) =>
      (not @opts.subtype?) or (typeof x is @opts.subtype) or (isClass and x instanceof @opts.subtype)

module.exports = ListProperty
