let pres = require("xbox.presence")
let {subscribe, subscribe_onehit} = require("eventbus")


let function set_presence(presence, callback) {
  let eventName = "xbox_set_presence"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    callback?(success)
  })
  pres.set_presence(presence, eventName)
}


let function retrieve_presences_for_users(users_list, callback) {
  let eventName = "xbox_get_presences_for_users"
  subscribe_onehit(eventName, function(result) {
    let success = result?.success
    let presences = result?.presences
    callback?(success, presences)
  })
  pres.get_presences_for_users(eventName, users_list)
}


let function subscribe_to_device_change_events(callback) {
  subscribe(pres.device_change_event_name, function(res) {
    let xuid = res?.xuid
    let devType = res?.dev_type
    let loggedIn = res?.logged_in
    callback?(xuid, devType, loggedIn)
  })
}


let function subscribe_to_title_change_events(callback) {
  subscribe(pres.title_change_event_name, function(res) {
    let xuid = res?.xuid
    let titleId = res?.title_id
    let titleState = res?.title_state
    callback?(xuid, titleId, titleState)
  })
}


return {
  UserPresence = pres.UserPresence
  DeviceType = pres.DeviceType
  TitleState = pres.TitleState

  subscribe_to_changes = pres.subscribe_to_changes
  unsubscribe_from_changes = pres.unsubscribe_from_changes

  set_presence
  retrieve_presences_for_users

  subscribe_to_device_change_events
  subscribe_to_title_change_events

  start_monitoring = pres.start_monitoring
  stop_monitoring = pres.stop_monitoring
}