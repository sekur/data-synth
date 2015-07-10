# SynthController

The `SynthController` provides actions and triggers for dealing with `SynthModels`.

    class SynthController extends (require './model')
      @set synth: 'controller'
      @include (require 'events').EventEmitter

    module.exports = SynthController
