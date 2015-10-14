
class BelongsToProperty extends (require './relationship')
  @set kind: 'belongsTo'

  access: (key) -> @fetch key if key is @value

  set: (value) ->
    try super
    catch e then throw new Error "unable to validate #{value} as belongs-to #{@model.get 'name'}"

  normalize: (value=@get()) ->
    switch
      when not value? then undefined
      when @model.instanceof value then switch
        when value.name is @model.get 'name' then value.id
        else "#{value.name}:#{value.id}"
      when typeof value is 'string' then switch
        when /.*:.*/.test value
          [ name, key ] = value.split ':'
          if name is @model.get 'name' then key else value
        else value
      when typeof value is 'number' then "#{value}"
      when value instanceof Array then undefined
      else undefined

  validate:  (value=@get()) ->
    (super value) is true and (not value? or not @opts['require-instance'] or @model.instanceof @fetch value)

  serialize: (opts={}) ->
    value=@get()
    if @opts.embedded is true
      value?.serialize? opts
    else
      super

module.exports = BelongsToProperty
