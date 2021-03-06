// Generated by CoffeeScript 1.9.3
var slice = [].slice;

(function(root, factory) {
  if (('function' === typeof define) && (define.amd != null)) {
    return define(['is_js', 'bluebird'], factory);
  } else if (typeof exports !== "undefined" && exports !== null) {
    return module.exports = factory(require('is_js'), require('bluebird'));
  } else {
    return root.waechter = factory(root.is, root.Promise);
  }
})(this, function(isjs, Promise) {
  var waechter;
  waechter = {
    errors: {}
  };
  waechter.predicateToValidator = function(predicate, error) {
    return function(value) {
      if (predicate(value)) {
        return null;
      } else {
        if ('function' === typeof error) {
          return error(value);
        } else {
          return error;
        }
      }
    };
  };
  waechter.schemaToValidator = function(schema) {
    return function(data) {
      var errors;
      if ('object' !== typeof data) {
        return 'must be an object';
      }
      errors = {};
      Object.keys(schema).forEach(function(key) {
        var error, validator;
        validator = schema[key];
        if ('function' !== typeof validator) {
          throw new Error("validator must be a function but is " + (typeof validator));
        }
        error = validator(data[key], data);
        if (error != null) {
          return errors[key] = error;
        }
      });
      Object.keys(data).forEach(function(key) {
        if (schema[key] == null) {
          return errors[key] = 'disallowed key';
        }
      });
      if (Object.keys(errors).length === 0) {
        return null;
      } else {
        return errors;
      }
    };
  };
  waechter.isThenable = function(x) {
    return (x === Object(x)) && ('function' === typeof x.then);
  };
  waechter.schemasToLazyAsyncValidator = function() {
    var schemas;
    schemas = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return function(data) {
      var errors, iterator;
      if ('object' !== typeof data) {
        return Promise.resolve('must be an object');
      }
      errors = {};
      iterator = function(schema, index) {
        var pending;
        pending = {};
        Object.keys(schema).forEach(function(key) {
          var error, validator;
          if (errors[key] != null) {
            return;
          }
          validator = schema[key];
          if ('function' !== typeof validator) {
            throw new Error("validator must be a function but is " + (typeof validator));
          }
          error = validator(data[key], data);
          if (waechter.isThenable(error)) {
            return pending[key] = error;
          } else if (error != null) {
            return errors[key] = error;
          }
        });
        if (index === 0) {
          Object.keys(data).forEach(function(key) {
            if (schema[key] == null) {
              return errors[key] = 'disallowed key';
            }
          });
        }
        return Promise.props(pending).then(function(resolved) {
          return Object.keys(resolved).forEach(function(key) {
            if (resolved[key] != null) {
              return errors[key] = resolved[key];
            }
          });
        });
      };
      return Promise.all(schemas).each(iterator).then(function() {
        if (Object.keys(errors).length === 0) {
          return null;
        } else {
          return errors;
        }
      });
    };
  };
  waechter.or = function() {
    var validators;
    validators = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return function(value) {
      var errors, i, len, results, validator;
      results = [];
      for (i = 0, len = validators.length; i < len; i++) {
        validator = validators[i];
        if ('function' !== typeof validator) {
          throw new Error("validator must be a function but is " + (typeof validator));
        }
        errors = validator(value);
        if (errors == null) {
          return null;
        }
        results.push(errors);
      }
      results.unshift('one of the following conditions must be fulfilled:');
      return results;
    };
  };
  waechter.and = function() {
    var validators;
    validators = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return function(value) {
      var errors, i, len, validator;
      for (i = 0, len = validators.length; i < len; i++) {
        validator = validators[i];
        if ('function' !== typeof validator) {
          throw new Error("validator must be a function but is " + (typeof validator));
        }
        errors = validator(value);
        if (errors != null) {
          return errors;
        }
      }
      return null;
    };
  };
  waechter.undefinedOr = function() {
    var validators;
    validators = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    return waechter.or.apply(waechter, [waechter.undefined].concat(slice.call(validators)));
  };
  waechter.exist = waechter.predicateToValidator(isjs.existy, function() {
    return waechter.errors.exist;
  });
  waechter.errors.exist = 'must not be null or undefined';
  waechter.string = waechter.and(waechter.exist, waechter.predicateToValidator(isjs.string, function() {
    return waechter.errors.string;
  }));
  waechter.errors.string = 'must be a string';
  waechter.stringNotEmpty = waechter.and(waechter.string, waechter.predicateToValidator(isjs.not.empty, function() {
    return waechter.errors.stringNotEmpty;
  }));
  waechter.errors.stringNotEmpty = 'must not be empty';
  waechter.email = waechter.and(waechter.string, waechter.predicateToValidator(isjs.email, function() {
    return waechter.errors.email;
  }));
  waechter.errors.email = 'must be an email address';
  waechter.number = waechter.predicateToValidator(isjs.number, function() {
    return waechter.errors.number;
  });
  waechter.errors.number = 'must be a number';
  waechter.boolean = waechter.predicateToValidator(isjs.boolean, function() {
    return waechter.errors.boolean;
  });
  waechter.errors.boolean = 'must be `true` or `false`';
  waechter.numberWithin = function(min, max) {
    var predicate;
    if (!(isjs.number(min) && isjs.number(max))) {
      throw new Error('min and max arguments must be numbers');
    }
    predicate = function(value) {
      return isjs.within(value, min, max);
    };
    return waechter.and(waechter.number, waechter.predicateToValidator(predicate, function() {
      return waechter.errors.numberWithin(min, max);
    }));
  };
  waechter.errors.numberWithin = function(min, max) {
    return "must be a number within " + min + " and " + max;
  };
  waechter.stringMinLength = function(min) {
    var predicate;
    predicate = function(value) {
      return value.length >= min;
    };
    return waechter.and(waechter.stringNotEmpty, waechter.predicateToValidator(predicate, function() {
      return waechter.errors.stringMinLength(min);
    }));
  };
  waechter.errors.stringMinLength = function(min) {
    return "must be at least " + min + " characters long";
  };
  waechter["true"] = function(value) {
    if (value !== true) {
      return waechter.errors["true"];
    }
  };
  waechter.errors["true"] = 'must be `true`';
  waechter["false"] = function(value) {
    if (value !== false) {
      return waechter.errors["false"];
    }
  };
  waechter.errors["false"] = 'must be `false`';
  waechter.undefined = waechter.predicateToValidator(isjs.undefined, function() {
    return waechter.errors.undefined;
  });
  waechter.errors.undefined = 'must be undefined';
  waechter["null"] = waechter.predicateToValidator(isjs["null"], function() {
    return waechter.errors["null"];
  });
  waechter.errors["null"] = 'must be undefined';
  return waechter;
});
