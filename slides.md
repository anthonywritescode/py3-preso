```rawhtml
<img src="build/python-logo.png" style="float: left">
```
## python3
### an intro

***

### outline

- definitions
- application structure
- changes + porting strategies

***

# definitions

***

## definitions: quick ones

- py2: python2.x (realistically 2.7)
- py3: python3.x (realistically >=3.3)
- py2+py3: code crafted to run under both versions
- six: a pretty-bare-bones python module for 2+3 compatibilty

***

## definitions: text

- human representation
- `"abc☃💩🐵"`
- string operations (slicing, replacing) are meaningful
- py2: `unicode`, py3: `str`

***

## definitions: bytes

- computer representation of text
- `b'abc\xe2\x98\x83\xf0\x9f\x92\xa9\xf0\x9f\x90\xb5'`
- string operations not meaningful (may break a character)
- py2: `bytes (str)`, py3: `bytes`

***

## definitons: native string

- the default string type used by that python version
- most stdlib apis written against this type
- py2 + py3: `str` (convenient!)

***

# application structure

***

```rawhtml
<div class="blob" style="background-color: #c22;">
    <h2>outside world</h2>
</div>
<div class="interfaces">
    <div>interfaces</div>
</div>
<div class="blob" style="background-color: #4078c0;">
    <h2>app</h2>
</div>
```

***

## interfaces

- network, filesystem, camera, etc.
- all speak in `byte`s
- encode to talk to them

***

## application

- collect data from interfaces
- compute business logic
- decode data from interfaces to use

***

## how?

- convert to bytes at boundaries
- deal with text internally
- pretty hard in py2! (we'll get to this)

***

## porting strategies
### to py2+py3 and beyond!

***

## at a high level

1. syntax passes
2. linting passes
3. importable
4. tests pass

***

# changes!

***

## feature flags

- new py3 features - enable them in py2 via flags
- enabled via imports from the `__future__` module
- easiest steps to writing py2+py3 compatible code
- turn on the flags on a per-module basis

***

`from __future__ import unicode_literals`

---

The default type for string literals in code becomes text.
In python2, strings were by-default `bytes`.
To explicitly make a `bytes` literal, use the `b''` prefix.

***

`from __future__ import absolute_import`

---

- Imports always start from `sys.path` roots.
- Importing a module `x` becomes unambiguous
- Adding a module can't break other modules' imports

***

`from __future__ import print_function`

---

- `print x`
- becomes: `print(x)`
- `print >>sys.stderr, x`
- becomes: `print(x, file=sys.stderr)`

***

`from __future__ import divison`

---

Not often as relevant.  Division changes to floating point
division by default in python3.  Use `x // y` to explicitly do integer division.

***

## moves

Many modules were non-pep8 named or poorly organized and were moved in py3.
A few examples:

- `ConfigParser` -> `configparser`
- `urlparse / urllib / urllib2` -> `urllib.parse, urllib.request, urllib.response`
- `SimpleHTTPServer` -> `http.server`

***

## moves (cont.)
`six.moves` provides easy access to the moved modules.
```python
from six.moves.urllib_error import URLError
from six.moves import range
```

***

## iterators
Many things which returned lists in py2 now return iterators.  `xrange` is gone and `range` is now an iterator.
`dict`s lose the `.iter{items,keys,values}()` functions.
***

## iterators (cont.)

- Often the iter{...} functions were faster in py2 than their list counterparts.  Sometimes not!
- If you're not terribly concerned about performance in py2, switch to use the py3 names (`range`, `.items()`, etc.).
- If you're concerned about performance, `six` provides helpers like `six.iteritems(dict_obj)` to use iterators in 2+3

***

## explicit string types

In python 2, adding a `str` object to a `unicode` object often just worked.
In py2, implicit conversion between `bytes` and `text` was allowed via the `US-ASCII` encoding.

```python
# py2
>>> 'foo' + u'☃'  # Implicitly 'foo'.decode('US-ASCII') + u'☃'
u'foo\u2603'
>>> '💩' + u'hi'  # Implicitly '💩'.decode('US-ASCII') + u'hi'
...
UnicodeDecodeError: 'ascii' codec can't decode byte 0xf0 in position 0: ordinal not in range(128)
>>> u'💩'.decode('UTF-8')  # implicitly u'💩'.encode('US-ASCII').decode('UTF-8')
...
UnicodeEncodeError: 'ascii' codec can't encode character u'\U0001f4a9' in position 0: ordinal not in range(128)
```

Each of these are a **western bias**!

***

## explicit string types

In python3, the `bytes` and `text` types are explicitly separated.
Mismatching of the two types is a `TypeError`

```python
# py3
>>> b'' + ''
TypeError: can't concat bytes to str
>>> '☃'.decode('UTF-8')
...
AttributeError: 'str' object has no attribute 'decode'
```

***

## explicit bytes type

- The `bytes` type in py2 gives the illusion that it is a useful string type.  Iterating it returns you 1-length bytes objects.
- In py3, iterating a `bytes` object gives you integers (each byte)
- `six` provides shims; ex: `six.iterbytes(...)`

***

## text apis everywhere!

The stdlib (wherever possible) now requires text objects where it previously allowed either `bytes` or `text`.
This makes it easier to write a correct application which deals with text internally.

***

## cheat sheet for string types

| have               | want  | code                |
| ------------------ | ----- | ------------------- |
| text               | bytes | `x.encode('UTF-8')` |
| bytes              | text  | `x.decode('UTF-8')` |
| object (int, etc.) | text  | `six.text_type(x)`  |

***

## files

- In py2 `open` yielded `bytes`, in py3, `open` gives you `text`
- Use `io.open` to get the python3 behaviour in python2

```python
with io.open('f.txt', encoding='UTF-8') as f:
    # ...
```

***

## subprocesses

subprocesses always return `bytes`.  `.decode()` their output to get text

```python
x = subprocess.check_output(('echo', 'hi')).decode('UTF-8')
```

***

## urls

In python2, the url libraries dealt with bytes, in python3 they're text apis which use UTF-8 for url encoding


Use `yelp_uri` to get the python3 behaviour in python2.

***

## http

http itself is a protocol of bytes.  In both py2 and py3, the low-level `Response` objects will generally give you `bytes` objects (for instance when accessing `.body`).

To work with text objects, generally pick some higher-level abstraction such as the `requests` library.

***

## c extensions
Relatively rare that you'll need to do this.
```c
#if PY_MAJOR_VERSION >= 3
#define PySass_IF_PY3(three, two) (three)
#define PySass_Int_FromLong(v) PyLong_FromLong(v)
#define PySass_Bytes_AS_STRING(o) PyBytes_AS_STRING(o)
#define PySass_Object_Bytes(o) PyUnicode_AsUTF8String(PyObject_Str(o))
#else
#define PySass_IF_PY3(three, two) (two)
#define PySass_Int_FromLong(v) PyInt_FromLong(v)
#define PySass_Bytes_AS_STRING(o) PyString_AS_STRING(o)
#define PySass_Object_Bytes(o) PyObject_Str(o)
#endif

/* ... */

PyObject* py_result = PyObject_CallFunction(pyfunc, PySass_IF_PY3("y", "s"), path);
PyObject* signature = PySass_Object_Bytes(sass_function);
```

***

## failures of py3
They couldn't get everything right!

- surrogateescape - fake characters hidden in text strings to work with POSIX filesystem apis
- PEP3333 - WSGI for py3.  As specced, the wsgi environ is **latin1** decoded text (**western bias**!  mojibake unless careful!).  `.encode('latin1').decode('UTF-8')` any time you need to access data

***

## links

- [What's new in Python3.0](https://docs.python.org/3.5/whatsnew/3.0.html)
- [six docs](http://six.readthedocs.io/)
- [six.py source](https://bitbucket.org/gutworth/six/src/tip/six.py)
