###*
# `RegistryProperty` is a hash map collection (holding value of type Object)
###
class RegistryProperty extends (require './property')

  constructor: (type, opts, obj) ->
    super 'object', opts, obj
    @set {} # initialize with empty object to start

  match: (query, keys=false) ->
    map = @get()
    switch
      when query instanceof Array
        for k, v of map when k in query
          if keys then k else v
      when query instanceof Object
        unless keys then (v for k, v of map).where query
        else
          results = []
          hit = Object.keys(query).length
          for key, item of map
            match = 0
            for k, v of query
              match += 1 if item[k] is v
            if match is hit
              results.push key
          results
      when query?
        unless keys then map[query]
        else
          if (map.hasOwnProperty query) then query else null
      when keys
        Object.keys map
      else
        (v for k, v of map)

  merge: (obj) -> @value[k] = v for k, v of obj

  remove: (query) ->
    keys = @match query, true
    switch
      when keys instanceof Array
        delete @value[key] for key in keys
      when keys?
        delete @value[keys]


EventEmitter = require('events').EventEmitter

###*
# SynthRegistry
#
# map of key: RegistryProperty
#
# primary methods:
#
# register()
# find()
# update()
# remove()
###
class SynthRegistry extends (require './object')
  @set storm: 'registry'
  @include EventEmitter

  @Property = RegistryProperty

  register: (key, property) -> @addProperty key, property

  keys: -> super.filter (key) => (@getProperty key) instanceof RegistryProperty

  find: (key, query) -> (@getProperty key)?.match query

  add: (key, value) -> (@getProperty key)?.merge value

  remove: (key, query) -> (@getProperty key)?.remove query

module.exports = SynthRegistry
