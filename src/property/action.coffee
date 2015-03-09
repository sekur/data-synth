assert = require 'assert'

class ActionProperty extends (require '../property')
  @set storm: 'action'

  kind: 'action'

  exec: -> throw new Error "undefined action"

  get: -> (require 'tosource') @exec

module.exports = ActionProperty
