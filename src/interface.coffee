class SynthInterface extends (require './meta')
  @set synth: 'interface', generator: undefined

  run: (app) -> (@constructor.get 'generator')?.call? app

module.exports = SynthInterface
