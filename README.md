# waechter

[![ALPHA](http://img.shields.io/badge/Stability-ALPHA-orange.svg?style=flat)]()
[![NPM Package](https://img.shields.io/npm/v/waechter.svg?style=flat)](https://www.npmjs.org/package/waechter)
[![Build Status](https://travis-ci.org/snd/waechter.svg?branch=master)](https://travis-ci.org/snd/waechter/branches)
[![Dependencies](https://david-dm.org/snd/waechter.svg)](https://david-dm.org/snd/waechter)

**simple, functional, sync/async validation for Node.js and browsers**

*inspired by [Prismatic/schema](https://github.com/Prismatic/schema)*

*waechter is german for guardian*

```
npm install waechter
```

```
bower install waechter
```

[lib/waechter.js](lib/waechter.js) supports [AMD](http://requirejs.org/docs/whyamd.html).
if [AMD](http://requirejs.org/docs/whyamd.html) is not available it sets the global variable `waechter`.

require:

```javascript
> var waechter = require('waechter');
```

<!--

waechter helps

whether data is **valid**.

helpful
useful error messages
providing some context and instructions.

user data.
-->

### predicates

a **predicate** is a function that takes a value and returns a boolean
indicating whether that value is **valid**.

[is.js](https://github.com/arasatasaygin/is.js)
is a big collection of **predicates**.  
waechter doesn't reinvent the wheel and uses [is.js](https://github.com/arasatasaygin/is.js) **predicates**:

```javascript
> var isjs = require('isjs');

> isjs.email('i am definitely not an email address');
false

> isjs.email('example@example.com');
true
```

### validators

a **validator** is a function that takes a value and
returns nothing (`null` or `undefined`) if the value is **valid**.
otherwise it returns a value describing the error.
that value is usually a string that is a helpful error message
or an object whose values are error messages.

you can make a **validator** from a **predicate** using `waechter.predicateToValidator`

```javascript
> var validateEmail = waechter.predicateToValidator(
  // the predicate
  isjs.email,
  // the value that is returned when the predicate returns false
  'must be an email address'
);
```

you can then use the **validator** to validate some data:

```javascript
> validateEmail('i am definitely not an email address');
'must be an email address'

> validateEmail('example@example.com');
null
```

### these validators are builtin

- `waechter.exist`
- `waechter.string`
- `waechter.stringNotEmpty`
- `waechter.email`
- `waechter.stringMinLength(min)`
- `waechter.number`
- `waechter.numberWithin(min, max)` (range is exclusive)
- `waechter.true`
- `waechter.false`
- `waechter.undefined`
- `waechter.null`
- `waechter.boolean`

you can easily make your own **validators** using `waechter.predicateToValidator`.

### composing validators

`waechter.and(validators...)` returns a validator that returns
null if all validators return null and otherwise returns the first error.

`waechter.or(validators...)` returns a validator that returns
null if at least one of the validators returns null and otherwise returns
an array of errors.

use `waechter.undefinedOr(validators...)` to make things optional.

### schemas

a **schema** is an object whose values are **validators**:

```javascript
> var userSchema = {
  email: waechter.email,
  password: waechter.stringNotEmpty
};
```

you can make a **validator** from a **schema**:

```javascript
> var validateUser = waechter.schemaToValidator(userSchema);
```

you can then use that **validator** to validate the structure of objects:

```javascript
> validateUser({
  email: 'invalid'
});
{
  email: 'must be an email address',
  password: 'must not be null or undefined'
}
```

```javascript
> validateUser({
  email: 'test@example.com',
  password: 'topsecret'
});
null
```

keys that are not present in the **schema** are not allowed in the data:

```javascript
> validateUser({
  email: 'test@example.com',
  password: 'topsecret'
  is_admin: true
});
{
  is_admin: 'disallowed key'
}
```

### async validators

an **async validator** is like a **validator** but returns a promise.

you can lazily (only when needed) run **async validators** after **sync validators** like so:

```javascript
> var userSchema = {
  email: waechter.email,
  password: waechter.stringNotEmpty
};

> var userSchemaAsync = {
  email: function(email) {
    return doesUserWithEmailAlreadyExistInDatabase(email).then(function(exists) {
      if (exists) {
        return 'taken';
      }
    });
  }
};

> validateUser = waechter.schemasToLazyAsyncValidator(
  userSchema,
  userSchemaAsync
);
```

you can mix schemas with sync and async validators in the arguments to
`waechter.schemasToLazyAsyncValidator`.

validators in later schemas are only run for keys that have no errors yet:

``` javascript
> validateUser({
  email: 'invalid'
}).then(function(errors) {
  > errors
  {
    email: 'must be an email address',
    password: 'must not be null or undefined'
  }
});
```
here the **validator** `userSchemaAsync.email` wasn't called.

``` javascript
> validateUser({
  email: 'taken@example.com'
}).then(function(errors) {
  > errors
  {
    email: 'taken',
    password: 'must not be null or undefined'
  }
});
```
this time the **validator** `userSchemaAsync.email` was called.

*[see the tests for more usage examples.](test/waechter.coffee)*

## [license: MIT](LICENSE)
