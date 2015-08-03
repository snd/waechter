Promise = require 'bluebird'

waechter = require '../src/waechter'

module.exports =

  'schemaToValidator': (test) ->
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

  'schemasToLazyAsyncValidator': (test) ->
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

  'or': (test) ->
    validator = waechter.or(
      waechter.email
      waechter.true
      waechter.numberWithin(6, 10)
    )

    test.deepEqual validator(), [
      'one of the following conditions must be fulfilled:'
      'must not be null or undefined'
      'must be `true`'
      'must be a number'
    ]
    test.equal validator(true), null
    test.deepEqual validator(10), [
      'one of the following conditions must be fulfilled:'
      'must be a string'
      'must be `true`'
      'must be a number within 6 and 10'
    ]
    test.equal validator(8), null
    test.deepEqual validator('aaa'), [
      'one of the following conditions must be fulfilled:'
      'must be an email address'
      'must be `true`'
      'must be a number'
    ]
    test.equal validator('test@example.com'), null
    test.done()

  'and': (test) ->
    validator = waechter.and(
      waechter.exist
      waechter.string
      waechter.stringNotEmpty
      waechter.email
    )

    test.equal validator(), 'must not be null or undefined'
    test.equal validator(5), 'must be a string'
    test.equal validator(''), 'must not be empty'
    test.equal validator('aaa'), 'must be an email address'
    test.equal validator('test@example.com'), null
    test.done()

  'numberWithin': (test) ->
    test.expect 8
    try
      test.equal waechter.numberWithin('a', 'b')
    catch e
      test.equal e.message, 'min and max arguments must be numbers'
    validator = waechter.numberWithin(2, 6)
    error = 'must be a number within 2 and 6'
    test.equal validator(1), error
    test.equal validator(2), error
    test.equal validator(3), null
    test.equal validator(4), null
    test.equal validator(5), null
    test.equal validator(6), error
    test.equal validator(7), error
    test.done()

  'true': (test) ->
    error = 'must be `true`'
    test.equal waechter.true(true), null
    test.equal waechter.true(false), error
    test.equal waechter.true(null), error
    test.equal waechter.true(), error
    test.equal waechter.true('true'), error
    test.done()

  'false': (test) ->
    error = 'must be `false`'
    test.equal waechter.false(false), null
    test.equal waechter.false(true), error
    test.equal waechter.false(null), error
    test.equal waechter.false(), error
    test.equal waechter.false('false'), error
    test.done()
