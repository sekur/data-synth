class ComputedProperty extends (require '../property')
  @set synth: 'computed', cache: 0, inherit: undefined
  @merge options: [ 'cache', 'func', 'inherit' ]

  constructor: ->
    # inherit = @constructor.get 'inherit'
    # if inherit?.constructor?
    #   @constructor.merge inherit
    #   @constructor.include inherit

    super
    console.assert @opts.func instanceof Function,
      "cannot instantiate a new ComputedProperty without a function"
    @cachedOn = new Date() if @opts.cache > 0

  get: ->
    unless @value? and (@opts.cache > 0 and (new Date() - @cachedOn)/1000 < @opts.cache)
      # XXX - handle @opts.async is 'true' in the future (return a Promise)
      @set (@opts.func.call @parent)
      @cachedOn = new Date() if @opts.cache > 0
    super

  set: (value) -> super if value?

module.exports = ComputedProperty
