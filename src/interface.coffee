class SynthInterface extends (require './meta')
  @set synth: 'interface', generator: undefined

  constructor: ->
    @name = @constructor.get 'name'
    super

  run: (app, args...) ->
    unless @running?
      @running = (@meta 'generator')?.apply? app, args
    return @running

  serialize: (opts={}) ->
    @constructor.extract 'name', 'description', 'needs'

module.exports = SynthInterface
