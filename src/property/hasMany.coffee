BelongsToProperty = require './belongsTo'

class HasManyProperty extends (require './relationship')
  @set kind: 'hasMany', unique: true, defaultValue: []

  get: -> (super.map (e) => @model::fetch e).filter (e) -> e?

  push: (value) ->
    list = @get()
    list.push value
    @set list

  validate: (value=@get()) -> (super value) is true and value.every (e) => (@model::fetch e) instanceof @model

  normalize: (value=@get()) ->
    value = super value
    super switch
      when value instanceof Array
        (value.filter (e) -> e?).map (e) => BelongsToProperty::normalize.call this, e
      else undefined

  serialize: (value=@get(), opts={}) ->
    if @opts.embedded is true
      value.map (e) -> e.serialize opts
    else
      super

module.exports = HasManyProperty
