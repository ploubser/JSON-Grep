JGrep is a command line tool and API for parsing JSON documents based on logical expressions.

### Installation:

jgrep is available as a gem:

    gem install jgrep

### JGrep binary usage:

    jgrep [expression] -i foo.json

or

    cat "foo.json" | jgrep [expression]

### Flags:

    -s, --simple [FIELDS]   : Greps the JSON and only returns the value of the field(s) specified
    -c, --compat            : Returns the JSON in its non-pretty flat form
    -n, --stream            : Specify continuous input
    -f, --flatten           : Flatten the results as much as possible
    -i, --input [FILENAME]  : Target JSON file to use as input
    -q, --quiet             : Quiet; don't write to stdout.  Exit with zero status if match found.
    -v, --verbose           : Verbose output that will list a document if it fails to parse
        --start FIELD       : Starts the grep at a specific key in the document
        --slice [RANGE]     : A range of the form 'n' or 'n..m', indicating which documents to extract from the final output

### Expressions:

JGrep uses the following logical symbols to define expressions.

    'and' :
        - [statement] and [statement]

        Evaluates to true if both statements are true

    'or' :
        - [statement] and [statement]

        Evaluates true if either statement is true

    'not' :
        - ! [statement]
        - not [statement]

        Inverts the value of statement

    '+'
        - +[value]

        Returns true if value is present in the json document

    '-'
        - -[value]

        Returns true if value is not present in the json doument

    '(' and ')'

        - (expression1) and expression2

        Performs the operations inside the perentheses first.

### Statements:

A statement is defined as some value in a json document compared to another value.
Available comparison operators are '=', '<', '>', '<=', '>='

Examples:

    foo.bar=1
    foo.bar>0
    foo.bar<=1.3

### Complex expressions:

Given a json document, {"foo":1, "bar":null}, the following are examples of valid expressions

Examples:

    +foo

... returns true

    -bar

... returns false

    +foo and !(foo=2)

... returns true

    !(foo>=2 and bar=null) or !(bar=null)

... returns true

### CLI missing an expression:

If JGrep is executed without a set expression, it will return an unmodified JSON document. The
-s flag can still be applied to the result.

### In document comparison:

If a document contains an array, the '[' and ']' operators can be used to define a comparison where
statements are checked for truth on a per element basis which will then be combined.

Example:

    [foo.bar1=1 and foo.bar2=2]

on

    [
      {
        "foo":  [
          {
            "bar1":1
          },
          {
            "bar2":2
          }
        ]
      },
      {
        "foo":  [
          {
            "bar1":0
          },
          {
            "bar2":0
          }
        ]
      }
    ]

will return

    [
      {
        "foo": [
          {
            "bar1": 1
          },
          {
            "bar2": 2
          }
        ]
      }
    ]


**Note**: In document comparison cannot be nested.

### The -s flag:

The s flag simplifies the output returned by JGrep. Given a JSON document

    [{"a":1, "b":2, "c":3}, {"a":3, "b":2, "c":1}]

a JGrep invocation like

    cat my.json | jgrep "a=1" -s b

will output

    1

The s flag can also be used with multiple field, which will return JSON as output which only contain the specified fields.
**Note**: Separate fields by a space and enclose all fields in quotes (see example below)

Given:

    [{"a":1, "b":2, "c":3}, {"a":3, "b":2, "c":1}]

a JGrep invocation like

    cat my.json | jgrep "a>0" -s "a c"

will output

    [
      {
        "a" : 1,
        "c" : 3
      },
      {
        "a" : 3,
        "c" : 1
      }
    ]

### The --start flag:

Some documents do not comply to our expected format, they might have an array embedded deep in a field.  The --start
flag lets you pick a starting point for the grep.

An example document can be seen here:

    {"results": [
                  {"name":"Jack", "surname":"Smith"},
                  {"name":"Jill", "surname":"Jones"}
                ]
    }

This document does not comply to our standard but does contain data that can be searched - the _results_ field.
We can use the --start flat to tell jgrep to start looking for data in that field:

<pre>
$ cat my.json | jgrep --start results name=Jack -s surname
Smith
</pre>

### The --slice flag

Allows the user to provide an int or range to slice an array of
results with, in particular so a single element can be extracted, e.g.

    $ echo '[{"foo": {"bar": "baz"}}, {"foo": {"bar":"baz"}}]' |
        jgrep "foo.bar=baz" --slice 0
    {
      "foo": {
        "bar": "baz"
      }
    }

### The --stream flag

With the --stream or -n flag, jgrep will process multiple JSON inputs (newline
separated) until standard input is closed.  Each JSON input will be processed
as usual, but the output immediately printed.

### JGrep Gem usage:

    require 'jgrep'

    json = File.read("yourfile.json")
    expression = "foo=1 or bar=1"

    JGrep::jgrep(json, expression)

    sflags = "foo"

    JGrep::jgrep(json, expression, sflags)

