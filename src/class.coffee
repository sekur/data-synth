
Array::equals = (x) -> @length is x.length and @every (e, i) -> e is x[i]

Array::unique = ->
    return @ unless @length > 0
    output = {}
    for key in [0..@length-1]
      val = @[key]
      switch
          when typeof val is 'object' and val.id?
              output[val.id] = val
          else
              output[val] = val
    #output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output

Array::contains = (query) ->
    return false if typeof query isnt "object"
    hit = Object.keys(query).length
    @some (item) ->
        match = 0
        for key, val of query
            match += 1 if item[key] is val
        if match is hit then true else false

Array::where = (query) ->
    return [] if typeof query isnt "object"
    hit = Object.keys(query).length
    @filter (item) ->
        match = 0
        for key, val of query
            match += 1 if item[key] is val
        if match is hit then true else false

Array::without = (query) ->
    return @ if typeof query isnt "object"
    @filter (item) ->
        for key,val of query
            return true unless item[key] is val
        false # item matched all query params

Array::pushRecord = (record) ->
    return null if typeof record isnt "object"
    @push record unless @contains(id:record.id)

class StormClass extends (require './meta')
  @set storm: 'class'
  @toJSON: (type='storm', tag=true) ->
    o = {}
    for k, v of this when v not instanceof Function and k isnt '__super__' and k isnt 'meta'
      o[k] = v
    for k, v of this.prototype when k isnt 'constructor' and v.meta?.storm?
      continue unless (v.get type)?
      prefix = (v.get type) + ':'
      o[prefix+k] = v.toJSON? type, false
    if tag is true
      prefix = (@get type)
      prefix += ':' + @meta.name if @meta.name?
      t = {}
      t[prefix] = o
      t
    else o

module.exports = StormClass
