# meta-class 

    class Meta
      @__meta__: synth: 'meta', bindings: {}, exports: {}
      @__version__: 3

## general utility helper functions

      tokenize = (key) -> ((key?.split? '.')?.filter (e) -> !!e) ? []

      @instanceof: (obj) ->
        (obj?.instanceof is arguments.callee or obj?.hasOwnProperty? '__meta__')
      @synthesized: (obj) ->
        (@instanceof obj) and (obj.get 'synth') is (@get 'synth')
      @copy: (dest={}, src) ->
        for p of src
          if src[p]?.constructor is Object
            dest[p] ?= {}
            unless dest[p].constructor is Object
              k = dest[p]
              dest[p] = {}
              dest[p][k] = undefined
            arguments.callee dest[p], src[p]
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
          @merge obj.extract 'bindings', 'exports'
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
        return Meta.copy {}, @__meta__ unless keys.length > 0
        res = {}
        Meta.copy res, Meta.objectify key, @get key for key in keys
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
        delete o.root[o.key] if o?

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
            Array.prototype.push.apply target, obj
          when target instanceof Object and obj instanceof Object
            @set "#{key}.#{k}", v for k, v of obj
          else
            console.assert typeof target is typeof obj,
              "cannot perform merge for '#{key}' with existing value type (#{typeof target}) conflicting with passed-in value (#{typeof obj})"
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
        [ key, rest... ] = tokenize key
        if rest.length > 0
          res = (@get "bindings.#{key}")?.bind? (rest.join '.'), obj
          console.assert res?,
            "unable to bind to non-existent prefix #{key}"
        else
          unless (@get "bindings.#{key}")? then @set "bindings.#{key}", obj
        this
        
      @unbind: (keys...)  ->
        unless keys.length > 0 then @clear 'bindings'; return this
        for key in keys when typeof key is 'string'
          [ key, rest... ] = tokenize key
          if rest.length > 0
            (@get "bindings.#{key}")?.unbind? (rest.join '.')
          else
            @delete "bindings.#{key}" 
        this

The following `reduce` provides meta data extrapolation by collapsing
nested `bindings` into object format for singular JS object output

      @reduce: ->
        o = meta: @extract()
        for key, val of o.meta.bindings
          o[key] = switch
            when (@instanceof val) then val.reduce()
            else val
        delete o.meta.bindings
        return o
        
## meta class instance prototypes

      constructor: (value, @container) ->
        return class extends Meta if @constructor is Object

        @attach k, v for k, v of (@constructor.get? 'bindings')
        @isConstructing = true
        @set value
        delete @isConstructing

      attach: (key, val) -> switch
        when (Meta.instanceof val)
          @properties ?= {}
          @properties[key] = new val undefined, this
          @isContainer = true
        when val instanceof Function
          @methods ?= {}
          @methods[key] = val
        when val?.constructor is Object
          (@attach "#{key}:#{k}", v) for k,v of val
        else
          @properties ?= {}
          @properties[key] = val

      fork: (f) -> f?.call? (new @constructor @get())

      meta: (key) -> @constructor.get key

      access: (key) ->
        [ key, rest... ] = tokenize key
        return unless key? and typeof key is 'string'
        prop = @properties?[key]
        return unless prop?
        switch
          when rest.length is 0 then prop
          else prop?.access? (rest.join '.')

      get: (key) ->
        [ key, rest... ] = tokenize key
        switch
          when @isContainer and key? then (@access key)?.get? (if rest.length then (rest.join '.') else undefined)
          when @isContainer
            @value = {}
            for k, v of @properties
              @value[k] = if v.get? then v.get?() else v
            @value
          when key? then rest.unshift key; Meta.get.call @value, rest.join '.'
          else @value
            
      set: (key, val) ->
        if typeof key is 'string' and val?
          key = Meta.objectify key, val
        if @isContainer and key instanceof Object
          (@access k)?.set v for k, v of key
        else
          @value = key
        this

      invoke: (name, args...) ->
        method = @methods?[name]
        console.assert method instanceof Function,
          "cannot invoke undefined '#{name}' method"
        method.apply this, args        
        
    module.exports = Meta
