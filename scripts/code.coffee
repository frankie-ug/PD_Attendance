RandomCodes = require('random-codes')
Firebase = require('firebase')
moment = require('moment')
_ = require('lodash')
authenticate = require('./authentication')
rootRef = authenticate.root
attendanceCodeRef = rootRef.child('attendance_code')
attendanceCodesRef = rootRef.child('attendance_codes')

config = {
  chars: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  separator: '-',
  mask: '*',
  parts: 4
  part_size: 4
}

module.exports = 
  generate: (number ,cb ) ->
    rc = new RandomCodes(config)
    attendanceCode = rc.generate()
    codes = []
    i = 1
    while i <= number
      code = rc.generate()
      codes.push(code)
      attendanceCodesRef.push({code: code})
      i++
    cb(codes)

  setAttendance: () ->
    today = moment(Date.now()).format('YYYYMMDD')
    rootRef.child('fellows').once 'value', (fellowSnap) ->
      fellowSnap.forEach (person) ->
        slackName = person.val().slack_id
        cohort = person.val().cohort.name != 'Class VIII'
        if slackName? & cohort
          user = rootRef.child('attendance').child(today).push()
          user.set({slack: slackName, attended:false})
        false

  verify: (enteredCode, cb) ->
    attendanceCodesRef.orderByChild('code').equalTo(enteredCode).on 'child_added', (snap) ->
      if snap.val()
        uid = snap.ref().key()
        attendanceCodesRef.child(uid).child('code').set 'used'
        return cb(true)
      cb(false)



