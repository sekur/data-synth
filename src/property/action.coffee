assert = require 'assert'

# XXX - need to fix this class

class ActionProperty extends (require '../property')
  @set synth: 'action'
  @merge options: [ 'exec' ]

  exec: -> throw new Error "undefined action"

  get: -> (require 'tosource') @exec

module.exports = ActionProperty
