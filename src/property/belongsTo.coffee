
class BelongsToProperty extends (require './relationship')
  @set kind: 'belongsTo'

  get: -> @model::fetch super

  normalize: (value=@get()) ->
    switch
      when not value? then undefined
      when value instanceof @model then value.get 'id'
      when typeof value is 'string' then value
      when typeof value is 'number' then "#{value}"
      when value instanceof Array then undefined
      when value instanceof Object
        record = new @model value
        @container.bind record
        @normalize record
      else undefined

  validate:  (value=@get()) -> (super value) is true and (not value? or @model::fetch value instanceof @model)

  serialize: (opts={}) ->
    value=@get()
    if @opts.embedded is true
      value?.serialize? opts
    else
      super

module.exports = BelongsToProperty
