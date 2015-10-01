# SynthStore

The `SynthStore` represents the primary container construct for managing various `Models`.

    #ModelRegistry = require './registry/model'
    class SynthStore extends (require './model')
      @set synth: 'store', models: undefined

The below `register` for `SynthStore` accepts one or more models and adds
to internal `ModelRegistry` instance.

      register: (models...) ->
        for model in models when (SynthStore.instanceof model)
          @constructor.merge "models.#{model.get 'name'}", model

PUBLIC access methods for working directly with internal models registry

      create: (type, data) ->
        model = @meta "models.#{type}"
        return unless model?
        new model data, this

      find: (type, query={}) ->
        model = @meta "models.#{type}"
        return unless model?
        switch
          when not (query instanceof Object) then model::fetch query
          when query.id? then model::fetch query.id
          else model::find query

      update: (type, id, data) -> null
      delete: (type, query) -> model.destroy() for model in (@find type, query)

    module.exports = SynthStore
