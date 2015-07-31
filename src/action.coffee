Promise = require 'promise'

class SynthAction extends (require './meta')
  @set synth: 'action'

  invoke: (app, event) ->
    console.log "calling invoke for #{event}"
    return new Promise (resolve, reject) =>
      action = this
      app.emit event, (@access 'input'), (@access 'output'), (err) ->
        if err? then reject action
        else resolve action

module.exports = SynthAction
