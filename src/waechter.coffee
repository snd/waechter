isjs = require 'is_js'
Promise = require 'bluebird'

module.exports = waechter =
  errors: {}

################################################################################
# higher order functions for validator composition

waechter.predicateToValidator = (predicate, error) ->
  (value) ->
    if predicate value
      null
    else
      if 'function' is typeof error
        error value
      else
        error

# can work recursively
# TODO add second argument flag allowAdditionalKeys that is false by default
# TODO dont allow additional keys
waechter.schemaToValidator = (schema) ->
  (data) ->
    unless 'object' is typeof data
      return 'must be an object'
    errors = {}
    Object.keys(schema).forEach (key) ->
      validator = schema[key]
      unless 'function' is typeof validator
        throw new Error "validator must be a function but is #{typeof validator}"
      error = validator data[key]
      if error?
        errors[key] = error
    if Object.keys(errors).length is 0
      null
    else
      errors

waechter.chainValidators = (validators...) ->
  (value) ->
    for validator in validators
      errors = validator value
      if errors?
        return errors
    null

waechter.isThenable = (x) ->
  (x is Object(x)) and ('function' is typeof x.then)

# TODO test this in isolation
waechter.schemasToLazyAsyncValidator = (schemas...) ->
  (data) ->
    unless 'object' is typeof data
      return Promise.resolve 'must be an object'

    errors = {}
    # we loop through all schemas in series
    iterator = (schema) ->
      pending = {}
      Object.keys(schema).forEach (key) ->
        if errors[key]?
          return
        validator = schema[key]
        unless 'function' is typeof validator
          throw new Error "validator must be a function but is #{typeof validator}"
        error = validator data[key]
        if waechter.isThenable error
          pending[key] = error
        else if error?
          errors[key] = error
      Promise.props(pending).then (resolved) ->
        Object.keys(resolved).forEach (key) ->
          if resolved[key]?
            errors[key] = resolved[key]
    Promise.all(schemas).each(iterator).then ->
      if Object.keys(errors).length is 0
        null
      else
        errors

waechter.optional = (validator) ->
  (value) ->
    if isjs.undefined value
      return
    validator value

################################################################################
# validators together with their default error messages

waechter.exist = waechter.predicateToValidator(
  isjs.existy
  -> waechter.errors.exist
)
waechter.errors.exist = 'must not be null or undefined'

waechter.string = waechter.chainValidators(
  waechter.exist
  waechter.predicateToValidator(isjs.string, -> waechter.errors.string)
)
waechter.errors.string = 'must be a string'

waechter.stringNotEmpty = waechter.chainValidators(
  waechter.string
  waechter.predicateToValidator(isjs.not.empty, -> waechter.errors.stringNotEmpty)
)
waechter.errors.stringNotEmpty = 'must not be empty'

waechter.email = waechter.chainValidators(
  waechter.string
  waechter.predicateToValidator(isjs.email, -> waechter.errors.email)
)
waechter.errors.email = 'must be an email address'

waechter.stringMinLength = (min) ->
  predicate = (value) ->
    value.length >= min
  waechter.chainValidators(
    waechter.stringNotEmpty
    waechter.predicateToValidator(predicate, -> waechter.errors.stringMinLength(min))
  )

waechter.errors.stringMinLength = (min) ->
  "must be at least #{min} characters long"
