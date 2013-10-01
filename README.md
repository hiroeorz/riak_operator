=================================================================
RiakOperator
=================================================================

riak_operator is client for Riak with Yokozuna.

This utility create for operator at riak.
It assumes that, this utility is used on a command line like psql or mysql. 

If you need library that is used in your application, you should use standard library by basho.

[basho/riak-ruby-client](https://github.com/basho/riak-ruby-client)

TODO: 
=================================================================

1. test
2. help

Installation
=================================================================

    $ git clone git@github.com:hiroeorz/riak_operator.git
    $ cd riak_operator
    $ bundle install --path=vendar/bundle

Usage
=================================================================

execute command
***************************************

If Riak(with yokozuna) executed on localhost

    bundle exec bin/riak_opearator

or other host

    bundle exec bin/riak_opearator -h 192.168.0.1

options

    --host  (-h) : riak host      ex: -h 192.168.0.1
    --port  (-p) : riak http port ex: -p 8098
    --ssl   (-s) : use ssl
    --debug (-d) : debug mode

Query
=================================================================

set index to bucket
***************************************

You need to set index to bucket at first (only once).

    > riak.create_index :my_bucket

insert
***************************************

insert with user defined key (example:1)

    > riak.insert :my_bucket, 1, name:"shin", age:37

or insert with automatically allocated key

    > riak.insert :my_bucket, name:"tuna", age:5



update
***************************************

    > riak.update :my_bucket, _id:1, set:{age:38}

    > riak.update :my_bucket, age:"[* TO 30]", set:{type:"young"}

find
***************************************

find all object (default max count is 100)

    > riak.find :my_bucket

result

    => [ [key1, {...}], [key2, {...}], [key3, {...}] ]

result example

    => [ ["3", {"name"=>"tuna", "age"=>5, "type"=>"young"}],
         ["1", {"name"=>"shin", "age"=>38}],
         ["2", {"name"=>"bio",  "age"=>4, "type"=>"young"}] ]

find by key

    > riak.find :my_bucket, 1
    
    or
    
    > riak.find :my_bucket, _id:1

find by name

    > riak.find :my_bucket, name:"shin"

find by name and age

    > riak.find :my_bucket, name:"shin", age:37

find by range of age

    > riak.find :my_bucket, age:"[20 TO 38]"
    
    > riak.find :my_bucket, age:"[* TO 38]"
    
    > riak.find :my_bucket, age:"[25 TO *]"

sort by key

    > riak.find :my_bucket, sort:"_yz_rk asc"

find by row q

    > riak.find :my_bucket, q:"age:[* TO 5] AND age:[45 TO *]"

delete field
***************************************

delete young field from all objects

    > riak.delete_field :my_bucket, :young

delete young field from objects that age is under 30

    > riak.delete_field :my_bucket, :young, age:"[0 TO 30]"


Contributing
=================================================================

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
