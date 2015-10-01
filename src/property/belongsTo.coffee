
class BelongsToProperty extends (require './relationship')
  @set kind: 'belongsTo'

  access: -> @model::fetch super

  set: (value) ->
    try super
    catch e then throw new Error "unable to validate #{value} as belongs-to #{@model.get 'name'}"

  normalize: (value=@get()) ->
    switch
      when not value? then undefined
      when @model.instanceof value  then value.get 'id'
      when typeof value is 'string' then value
      when typeof value is 'number' then "#{value}"
      when value instanceof Array then undefined
      else undefined

  validate:  (value=@get()) ->
    (super value) is true and (not value? or @model.instanceof (@model::fetch value))

  serialize: (opts={}) ->
    value=@get()
    if @opts.embedded is true
      value?.serialize? opts
    else
      super

module.exports = BelongsToProperty
