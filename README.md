# waechter

[![ALPHA](http://img.shields.io/badge/Stability-ALPHA-orange.svg?style=flat)]()
[![NPM Package](https://img.shields.io/npm/v/waechter.svg?style=flat)](https://www.npmjs.org/package/waechter)
[![Build Status](https://travis-ci.org/snd/waechter.svg?branch=master)](https://travis-ci.org/snd/waechter/branches)
[![Dependencies](https://david-dm.org/snd/waechter.svg)](https://david-dm.org/snd/waechter)

**simple, functional, sync/async validation for Node.js and browsers**

*inspired by [Prismatic/schema](https://github.com/Prismatic/schema)*

*waechter is german for guardian*

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

---

a **validator** is a function that takes a value and
returns nothing (`null` or `undefined`) if the value is **valid**.
otherwise it returns a value describing the error.
that value is usually a string that is a helpful error message
or an object whose values are error messages.

you can make a **validator** from a predicate like so:

```javascript
> var validateEmail = waechter.predicateToValidator(
  // the predicate
  isjs.email,
  // the value that is returned when the predicate returns false
  'must be an email address'
);

> validateEmail('i am definitely not an email address');
'must be an email address'

> validateEmail('example@example.com');
null
```

waechter currently comes with the following validators:

- `exist`
- `string`
- `stringNotEmpty`
- `email`
- `stringMinLength(min)`

you can easily make your own using `predicateToValidator`.

---

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

*more documentation (especially on async validation) is coming soon !*

*[also see the tests for more usage examples.](test/waechter.coffee)*

## [license: MIT](LICENSE)
