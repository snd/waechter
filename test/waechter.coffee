Promise = require 'bluebird'

waechter = require '../src/waechter'

module.exports =

  'sync': (test) ->
    userSchema =
      email: waechter.email
      password: waechter.stringNotEmpty

    validateUser = waechter.schemaToValidator userSchema

    test.equal validateUser(), 'must be an object'

    test.deepEqual validateUser({
    }), {
      email: 'must not be null or undefined'
      password: 'must not be null or undefined'
    }

    test.deepEqual validateUser({
      email: 'i am definitely not an email address'
      password: ''
    }), {
      email: 'must be an email address'
      password: 'must not be empty'
    }

    test.deepEqual validateUser({
      email: 'test@example.com'
    }), {
      password: 'must not be null or undefined'
    }

    test.equal validateUser({
      email: 'test@example.com'
      password: 'topsecret'
    }), null

    test.done()

  'async': (test) ->
    schemaUserShared =
      name: waechter.stringNotEmpty
      password: waechter.stringMinLength(8)
      email: waechter.email

    callsToFirstUserWhereName = []

    firstUserWhereName = (name) ->
      callsToFirstUserWhereName.push name
      if name is 'this-name-is-taken'
        Promise.delay({}, 10)
      else
        Promise.delay(null, 10)

    callsToFirstUserWhereEmail = []

    firstUserWhereEmail = (email) ->
      callsToFirstUserWhereEmail.push email
      if email is 'this-email-is-taken@example.com'
        Promise.delay({}, 10)
      else
        Promise.delay(null, 10)

    schemaUserTakenAsync =
      name: (value) ->
        firstUserWhereName(value).then (user) ->
          if user? then 'taken'
      email: (value) ->
        firstUserWhereEmail(value).then (user) ->
          if user? then 'taken'

    validateUser = waechter.schemasToLazyAsyncValidator(
      schemaUserShared
      schemaUserTakenAsync
    )

    validateUser()
      .then (errors) ->
        test.equal errors, 'must be an object'

        validateUser
          email: 'i am definitely not an email address'
          password: ''
      .then (errors) ->
        test.deepEqual errors,
          email: 'must be an email address'
          name: 'must not be null or undefined'
          password: 'must not be empty'

        validateUser
          email: 'i am definitely not an email address'
          name: ''
          password: 'foo'
      .then (errors) ->
        test.deepEqual errors,
          email: 'must be an email address'
          name: 'must not be empty'
          password: 'must be at least 8 characters long'

        validateUser
          email: 'i am definitely not an email address'
          name: 'a'
          password: 'foo'
      .then (errors) ->
        test.deepEqual errors,
          email: 'must be an email address'
          password: 'must be at least 8 characters long'

        validateUser
          email: 'test@example.com'
          name: 'a'
          password: 'topsecret'
      .then (errors) ->
        test.equal errors, null

        validateUser
          email: 'test@example.com'
          name: 'this-name-is-taken'
          password: 'topsecret'
      .then (errors) ->
        test.deepEqual errors,
          name: 'taken'

        validateUser
          email: 'this-email-is-taken@example.com'
          name: 'this-name-is-taken'
          password: 'topsecret'
      .then (errors) ->
        test.deepEqual errors,
          name: 'taken'
          email: 'taken'

        test.deepEqual callsToFirstUserWhereName, ['a', 'a', 'this-name-is-taken', 'this-name-is-taken']
        test.deepEqual callsToFirstUserWhereEmail, ['test@example.com', 'test@example.com', 'this-email-is-taken@example.com']

        test.done()
