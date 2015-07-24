class SynthInterface extends (require './meta')
  @set synth: 'interface', generator: undefined

  run: (app, args...) -> (@constructor.get 'generator')?.apply? app, args

  serialize: (opts={}) ->
    @constructor.extract 'name', 'description', 'needs'

module.exports = SynthInterface
