BelongsToProperty = require './belongsTo'

class HasManyProperty extends (require './relationship')
  @set kind: 'hasMany', unique: true, default: []

  access: -> (super.map (e) => @fetch e).filter (e) -> e?

  push: (value) ->
    list = @get()
    list.push value
    @set list

  set: (value) ->
    try super
    catch e then throw new Error "unable to validate has-many relationship of #{@model.get 'name'}"

  normalize: (value=@get()) ->
    value = super value
    super switch
      when value instanceof Array
        (value.filter (e) -> e?).map (e) => BelongsToProperty::normalize.call this, e
      else undefined

  validate: (value=@get()) ->
    (super value) is true and value.every (e) => not @opts['require-instance'] or @model.instanceof (@fetch e)

  serialize: (opts={}) ->
    value=@get()
    if @opts.embedded is true
      value.map (e) -> e.serialize opts
    else
      super

module.exports = HasManyProperty
