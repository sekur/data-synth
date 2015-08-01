Promise = require 'promise'

class SynthAction extends (require './meta')
  @set synth: 'action', event: undefined

  invoke: (origin, event=(@meta 'name'), container=@container) ->
    listeners = container.listeners event
    console.log "invoking '#{event}' for handling by #{listeners.length} listeners"
    action = this
    promises =
      for listener in listeners
        do (listener) ->
          new Promise (resolve, reject) ->
            listener.apply container, [
              (action.access 'input')
              (action.access 'output')
              (err) -> if err? then reject err else resolve action
              origin
            ]
    unless promises.length > 0
      promises.push Promise.reject "missing listeners for '#{event}' event"

    return Promise.all promises
      .then (res) ->
        console.log "promise all returned with"
        console.log res
        for action in res
          console.log "got back #{action} from listener"

  trigger: (origin, event=(@meta 'name')) ->
    console.log "emit '#{event}' for handling by listeners"
    @container.emit event, (@access 'input'), (@access 'output'), (err) -> 

module.exports = SynthAction
