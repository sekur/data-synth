BelongsToProperty = require './belongsTo'

class HasManyProperty extends (require './relationship')
  @set storm: 'hasMany'

  kind: 'hasMany'

  get: -> (super.map (e) => @model::fetch e).filter (e) -> e?

  push: (value) ->
    list = @get()
    list.push value
    @set list

  validate: (value=@value) -> (super value) is true and value.every (e) => (@model::fetch e) instanceof @model

  normalize: (value) ->
    # console.log "normalizing hasMany for #{@model['meta-name']}"
    value = super value
    super switch
      when value instanceof Array
        (value.filter (e) -> e?).map (e) => BelongsToProperty::normalize.call this, e
      else undefined

  serialize: (format='json') ->
    # console.log 'serializing hasMany...'
    # console.log @value
    if @opts.embedded is true
      @get().map (e) -> e.serialize format
    else
      super

module.exports = HasManyProperty
