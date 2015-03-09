
class BelongsToProperty extends (require './relationship')
  @set storm: 'belongsTo'

  kind: 'belongsTo'

  get: -> @model::fetch super

  validate:  (value=@value) -> (super value) is true and (not value? or @model::fetch value instanceof @model)
  normalize: (value) ->
    # console.log 'belongsTo.normalize'
    # console.log value
    # console.log (value instanceof @model)
    switch
      when not value? then undefined
      when value instanceof @model then value.get 'id'
      when typeof value is 'string' then value
      when typeof value is 'number' then "#{value}"
      when value instanceof Array then undefined
      when value instanceof Object
        record = new @model value
        @obj.bind record
        @normalize record
      else undefined

  serialize: (format='json') ->
    if @opts.embedded is true
      @get().serialize format
    else
      super

module.exports = BelongsToProperty
