((root, factory) ->
  # amd
  if ('function' is typeof define) and define.amd?
    define(['is_js', 'bluebird'], factory)
  # nodejs
  else if exports?
    module.exports = factory(
      require('is_js')
      require('bluebird')
    )
  # other
  else
    root.waechter = factory(root.is, root.Promise)
)(this, (isjs, Promise) ->

  waechter =
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

  # TODO make this work recursively
  waechter.schemaToValidator = (schema) ->
    (data) ->
      unless 'object' is typeof data
        return 'must be an object'
      errors = {}

      Object.keys(schema).forEach (key) ->
        validator = schema[key]
        unless 'function' is typeof validator
          throw new Error "validator must be a function but is #{typeof validator}"
        error = validator data[key], data
        if error?
          errors[key] = error

      Object.keys(data).forEach (key) ->
        unless schema[key]?
          errors[key] = 'disallowed key'

      if Object.keys(errors).length is 0
        null
      else
        errors

  waechter.isThenable = (x) ->
    (x is Object(x)) and ('function' is typeof x.then)

  # TODO test this in isolation
  waechter.schemasToLazyAsyncValidator = (schemas...) ->
    (data) ->
      unless 'object' is typeof data
        return Promise.resolve 'must be an object'

      errors = {}
      # we loop through all schemas in series
      iterator = (schema, index) ->
        pending = {}

        Object.keys(schema).forEach (key) ->
          if errors[key]?
            return
          validator = schema[key]
          unless 'function' is typeof validator
            throw new Error "validator must be a function but is #{typeof validator}"
          error = validator data[key], data
          if waechter.isThenable error
            pending[key] = error
          else if error?
            errors[key] = error

        # only check for disallowed key in first schema
        if index is 0
          Object.keys(data).forEach (key) ->
            unless schema[key]?
              errors[key] = 'disallowed key'

        Promise.props(pending).then (resolved) ->
          Object.keys(resolved).forEach (key) ->
            if resolved[key]?
              errors[key] = resolved[key]
      Promise.all(schemas).each(iterator).then ->
        if Object.keys(errors).length is 0
          null
        else
          errors

  ################################################################################
  # validator combinators

  # requires at least one validator to return null
  # TODO async ?
  waechter.or = (validators...) ->
    # TODO at least one validator
    (value) ->
      results = []
      for validator in validators
        unless 'function' is typeof validator
          throw new Error "validator must be a function but is #{typeof validator}"
        errors = validator value
        unless errors?
          return null
        results.push errors
      results.unshift 'one of the following conditions must be fulfilled:'
      return results

  # requires all validators to return null
  # TODO async ?
  waechter.and = (validators...) ->
    # TODO at least one validator
    (value) ->
      for validator in validators
        unless 'function' is typeof validator
          throw new Error "validator must be a function but is #{typeof validator}"
        errors = validator value
        if errors?
          return errors
      return null

  waechter.undefinedOr = (validators...) ->
    waechter.or(waechter.undefined, validators...)

  ################################################################################
  # validators together with their default error messages

  waechter.exist = waechter.predicateToValidator(
    isjs.existy
    -> waechter.errors.exist
  )
  waechter.errors.exist = 'must not be null or undefined'

  waechter.string = waechter.and(
    waechter.exist
    waechter.predicateToValidator(isjs.string, -> waechter.errors.string)
  )
  waechter.errors.string = 'must be a string'

  waechter.stringNotEmpty = waechter.and(
    waechter.string
    waechter.predicateToValidator(isjs.not.empty, -> waechter.errors.stringNotEmpty)
  )
  waechter.errors.stringNotEmpty = 'must not be empty'

  waechter.email = waechter.and(
    waechter.string
    waechter.predicateToValidator(isjs.email, -> waechter.errors.email)
  )
  waechter.errors.email = 'must be an email address'

  waechter.number = waechter.predicateToValidator(isjs.number, -> waechter.errors.number)
  waechter.errors.number = 'must be a number'

  # exclusive
  waechter.numberWithin = (min, max) ->
    unless isjs.number(min) and isjs.number(max)
      throw new Error 'min and max arguments must be numbers'
    predicate = (value) ->
      isjs.within value, min, max
    waechter.and(
      waechter.number
      waechter.predicateToValidator(
        predicate
        -> waechter.errors.numberWithin(min, max)
      )
    )
  waechter.errors.numberWithin = (min, max) -> "must be a number within #{min} and #{max}"

  waechter.stringMinLength = (min) ->
    predicate = (value) ->
      value.length >= min
    waechter.and(
      waechter.stringNotEmpty
      waechter.predicateToValidator(predicate, -> waechter.errors.stringMinLength(min))
    )
  waechter.errors.stringMinLength = (min) ->
    "must be at least #{min} characters long"

  waechter.true = (value) ->
    unless value is true
      waechter.errors.true
  waechter.errors.true = 'must be `true`'

  waechter.false = (value) ->
    unless value is false
      waechter.errors.false
  waechter.errors.false = 'must be `false`'

  waechter.undefined = waechter.predicateToValidator(isjs.undefined, -> waechter.errors.undefined)
  waechter.errors.undefined = 'must be undefined'

  waechter.null = waechter.predicateToValidator(isjs.null, -> waechter.errors.null)
  waechter.errors.null = 'must be undefined'

  return waechter
)
