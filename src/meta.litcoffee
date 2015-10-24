# meta-class 

    Promise = require 'promise'
    class Meta
      @__meta__: synth: 'meta'
      @__version__: 3

## general utility helper functions

      tokenize = (key) -> ((key?.split? '.')?.filter (e) -> !!e) ? []

      @instanceof: (obj) ->
        (obj?.instanceof is arguments.callee or obj?.hasOwnProperty? '__meta__')
      @synthesized: (obj) ->
        (@instanceof obj) and (obj.get 'synth') is (@get 'synth')
      @copy: (dest={}, src, append=false) ->
        for p of src
          switch
            when src[p]?.constructor is Object
              dest[p] ?= {}
              unless dest[p] instanceof Object
                k = dest[p]
                dest[p] = {}
                dest[p][k] = null
              arguments.callee dest[p], src[p], append
            when append is true and dest[p]?
              unless dest[p] instanceof Object
                k = dest[p]
                dest[p] = {}
                dest[p][k] = null
              dest[p][src[p]] = null
            else dest[p] = src[p]
        return dest
      @objectify: (key, val) ->
        return key if key instanceof Object
        composite = tokenize key
        unless composite.length
          return val ? {}
          
        obj = root = {}
        while (k = composite.shift())
          last = r: root, k: k
          root = root[k] = {}
        last.r[last.k] = val
        obj

## class object operators (on this)

      @configure: (f, args...) -> f?.apply? this, args; this

      @extend: (obj) ->
        @[k] = v for k, v of obj when k isnt '__super__' and k not in Object.keys Meta
        this

      @include: (obj) ->
        @::[k] = v for k, v of obj when k isnt 'constructor' and k not in Object.keys Meta.prototype
        this

The `mixin` convenience function essentially fuses the target class
obj(s) into itself.

      @mixin: (objs...) ->
        for obj in objs when obj instanceof Object
          @extend obj
          @include obj.prototype
          continue unless Meta.instanceof obj
          # when mixing in another Meta object, merge the 'bindings'
          # as well
          @merge obj.extract 'bindings'
        this

## meta data operators (on this.__meta__)

The following `get/extract/match` provide meta data retrieval mechanisms.
 
      @get: (key) ->
        return unless key? and typeof key is 'string'
        root = @__meta__ ? this
        composite = tokenize key
        root = root?[key] while (key = composite.shift())
        root
      @extract: (keys...) ->
        return Meta.copy {}, (@__meta__ ? this) unless keys.length > 0
        res = {}
        Meta.copy res, Meta.objectify key, (@get? key) ? @[key] for key in keys
        res
      @match: (regex) ->
        root = @__meta__ ? this
        obj = {}
        obj[k] = v for k, v of root when (k.match regex)
        obj

The following `clear/delete` provides meta data removal mechanisms

      unwindObject = (obj, key) ->
        [ pre..., key ] = tokenize key
        return unless obj? and key?
        obj = obj[k] while k = pre.shift() when obj instanceof Object
        return root: obj, key: key if obj?

      @clear: (key) ->
        o = unwindObject (@__meta__ ? this), key
        return unless o?
        val = o.root[o.key]
        o.root[o.key] = switch
          when val instanceof Array  then []
          when val instanceof Object then {}
          else undefined

      @delete: (key) ->
        o = unwindObject (@__meta__ ? this), key
        return unless o?
        orig = o.root[o.key]
        delete o.root[o.key]
        return orig

The following `set/merge` provide meta data update mechanisms.
        
      @set: (key, val) ->
        obj = Meta.objectify key, val
        @__meta__ = Meta.copy (Meta.copy {}, @__meta__), obj
        this
      @merge: (key, obj) ->
        return this unless key?
        unless typeof key is 'string'
          (@merge k, v) for k, v of (key.__meta__ ? key) when k isnt 'synth'
          return this
        target = @get key
        switch
          when not target? then @set key, obj
          when (Meta.instanceof target) and (Meta.instanceof obj)
            target.merge obj
          when target instanceof Function and obj instanceof Function
            target.mixin? obj
          when target instanceof Array and obj instanceof Array
            @set key, target.concat obj...
          when target instanceof Object and obj instanceof Object
            @set "#{key}.#{k}", v for k, v of obj
          when typeof target is typeof obj
            @set key, obj
          else
            console.log "performing merge for '#{key}' with existing value type (#{typeof target}) conflicting with passed-in value (#{typeof obj})"
            @set key, obj
        this

The `bind` function associates the passed in key/object into the meta
class so that when this class object is instantiated, all the bound
objects are actualized during construction.  It protects the key under
question so that the binding can only take place once for a given key.
Nested bindings are also supported but only if nested keys each
resolve to a pre-existing instance of Meta class that supports `bind`
function.
        
      @bind: (key, obj) ->
        return this unless key?
        unless typeof key is 'string'
          (@bind k, v) for k, v of key
          return this
        [ key, rest... ] = tokenize key
        if rest.length > 0
          res = (@get "bindings.#{key}")?.bind? (rest.join '.'), obj
          console.assert res?,
            "unable to bind to non-existent prefix #{key}"
        else
          unless (@get "bindings.#{key}")? then @set "bindings.#{key}", obj
        this
        
      @unbind: (key)  ->
        unless key? then @clear 'bindings'; return this
        [ key, rest... ] = tokenize key
        if rest.length > 0
          (@get "bindings.#{key}")?.unbind? (rest.join '.')
        else
          @delete "bindings.#{key}"

      @rebind: (key, target) ->
        prev = @unbind key
        if target instanceof Function
          @bind key, target.call this, prev
        else
          @bind key, target

The following `reduce` provides meta data extrapolation by collapsing
nested `Meta` instances into object format for singular JS object
output

      @reduce: (opts={}) ->
        meta = @extract()
        o = meta: meta
        if not opts.depth? or opts.depth-- > 0
          for key, val of meta.bindings
            o[key] = switch
              when (@instanceof val) then val.reduce opts
              else val
        delete meta.bindings
        for key, val of meta
          meta[key] = switch
            when (@instanceof val) then val.reduce opts
            else val
        return o
        
## meta class instance prototypes

      constructor: (value, parent) ->
        return class extends Meta if @constructor is Object
        @parent = parent if parent?
        bindings = (@constructor.extract 'bindings').bindings
        bindings ?= {}
        for idx, override of (@constructor.get 'overrides')
          for k, v of override
            if v instanceof Function
              bindings[k] = v.call @constructor, bindings[k]
            else
              bindings[k] = v
        @attach k, v for k, v of bindings
        @set value if value?

      attach: (key, val) ->
        switch
          when (Meta.instanceof val)
            @properties ?= {}
            @properties[key] = new val undefined, this
          when val instanceof Function
            @methods ?= {}
            @methods[key] = val
          when val?.constructor is Object
            (@attach "#{key}:#{k}", v) for k,v of val
          else
            @properties ?= {}
            @properties[key] = val

      detach: (key) ->
        match = @access key
        return unless match?

        [ rest..., key ] = tokenize key
        if match?.parent?.properties?.hasOwnProperty key
          delete match.parent.properties[key]
        return match

      fork: (f, args...) -> f?.apply? (new @constructor @get()), args

      meta: (key) -> @constructor.get key

      access: (key) ->
        [ key, rest... ] = tokenize key
        return unless key? and typeof key is 'string'
        prop = @properties?[key]
        return unless prop?
        switch
          when rest.length is 0 then prop
          else prop?.access? (rest.join '.')

      seek: (query, meta=true) ->
        return unless typeof query is 'object'
        for k, v of query
          value = switch
            when (this instanceof Meta) then (if meta then @meta k else @get k)
            else @[k]
          unless (switch
            when v instanceof Function then (v.call this, value)
            else value is v)
            return unless @parent?
            return arguments.callee.call @parent, query, meta
        return this

      get: (key) ->
        [ key, rest... ] = tokenize key
        switch
          when @properties? and key?
            p = @access key
            if p?.get? then p.get (if rest.length then (rest.join '.') else undefined)
            else p
          when @properties?
            @value = {}
            for k, v of @properties
              @value[k] = if v.get? then v.get?() else v
            @value
          when key? then rest.unshift key; Meta.get.call @value, rest.join '.'
          else @value
            
      set: (key, val) ->
        if typeof key is 'string' and val?
          key = Meta.objectify key, val
        if @properties? and key instanceof Object
          for k, v of key when @properties.hasOwnProperty k
            p = @access k
            if p?.set? then p.set v else @properties[k] = v
        else
          @value = key
        this

      invoke: (input, args...) ->
        if input instanceof Array
          # a magical one-liner...
          return Promise.all input.map (f) => @invoke ([f].concat args)...

        method = input if input instanceof Function
        method ?= @methods?[input]
        unless method instanceof Function
          return Promise.reject "cannot invoke undefined '#{input}' method"

        new Promise (resolve, reject) =>
          method.apply this, args.concat [ resolve, reject ]

      valueOf:  -> @constructor.extract()
      toString: -> @meta 'name' ? @meta 'synth'
        
    module.exports = Meta
