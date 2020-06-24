# CH 5 Working with ActiveRecord

- Active Record pattern: one domain class maps to one database table, one instance of the class represents one row
- Rails Active Record implemented base on pattern above and extends funcitonality based on that
  - CRUD
  - searches
  - validations
  - callbacks
  - ...etc

# 5.1 Basics
- every model class inherits from `ApplicationRecord`
- in dev mode, changes to schema reflected in ActiveRecord immediatly
  - console needs to have reload!
- adhere to the Golden Path
  - stay within its limitations, go far. Stray from it, might get stuck in the mud
  
# 5.2 Macro-Style Methods
- configurations of models should go on top of file (like the `has_many` associations)
  - so people can immediatly understand how it is configured
- convention over configuration
  - configure as few things as possible
  - configurations like `self.table_name`  or `self.primary_key` can be used for legacy apps
  - or table pluralization in active_record on the config level

# 5.3  Attributes
- usually implicitly from the database fields
- to change default behavior, a few options
  - use the `attribute` api and define it at the top of the model
  - `read_attribute` or `write_attribute` apis
  - access with `self[:<field>]` and write with `self[:<field>] = "some val"`

# 5.4 CRUD
- making new active record models instances
  - `<Model>.new` does not save in DB
    - `new_record?` and `persisted?` can be used to check
  - `<Model>.create` creates record in DB
  - both new and create takes a block argument for further initialization
    - attributes can be updated here but don't see why we would
- reading
  - `find`
    - raises RecordNotFound error if not found
    - can take an array of ids
  - `take(<Integer>)`
    - grabs the first x number of records
  - you can over write getter and setter for an attribute by using the `read_attribute` method and `write_attribute` api
    - we don't use `self` for read overrides because of recursion
  - `<instance>.attributes` grabs all the attributes in a hash
  - `*attribute*_before_type_cast` allows you to access an attribute before they are typecasted (i.e. original value from db)
- reload will refetch attributes from db
- cloning will get a shallow copy of the object
  - associations will be another DB fall due to memory concerns
- queries are cached by default
  - dumb cache so if the query looks different, another one will be cache
  - query will be cached for that one db connection
  - how many times cached results are read are shown in the logs
- Updating
  - `update` supports single and multiple instances
  - `find`, then `save` works as well
  - `update_attribute` method will skip validations. should not be used unless there is a really good reason
  - `touch` will just update the `updated_at` timestamp
  - can be set on the association so that when you touch the instance, it will also touch parent
- Delete
  - `destroy` will load all the instances in rails, and call destroy related callbacks on all of them
  - `delete` will just run delete in query level

# 5.5 Database Locking
- prevent concurrent users of an app from overwriting each other's work
- Optimistic Locking
  - on rails level -> DB is not aware
  - used when collisions are infrequent
  - executed by adding a column named `:lock_version`
    - can be renamed to something else if desired
  ```ruby
    class ADdLockVersionToTimeSheets < ActiveRecord::Migration
      def change
        add_column :timesheets, :lock_version, :integer, default: 0
      end
    end
  ```
  - `ActiveRecord::StabeObjectError will be raise
  ```ruby
    describe Timesheet do
      it "locks optimistically" do
        t1 = Timesheet.create
        t2 = Timesheet.find(t1.id)

        t1.rate = 250
        t2.rate = 175

        expect(t1.save).to be_true
        expect{t2.save}.to raise_error(ActiveRecord::StaleObjectError)
      end
    end
  ```
- Pessimistic Locking 
  - requries DB support by actually locking the rows being acted on
  - uses the `FOR UPDATE` clause on the select
  ```ruby
  Timesheet.transaction do
    t = Timesheet.lock.first # or on existing instance, <instance>.reload(lock: true)
    t.approved = true
    t.save!
  end
  ```
- Optimistic are generally sufficient as Pessimistic locking can prevent records from being read for a long time and thus block thread execution


# 5.6 Querying
- try to use default querying API
  - safety. Less SQL injection
  - can work across multiple databases
  - readability 
- `nil` can be intepreted when subbed into a field as `null`
- take and skip can be used to perform pagination
  - `Timesheet.take(10).skip(10)`
- `select` can be used to select specific fields
- `includes` can be used to grab associations in one query if possible (via joins), if not it does it via multiple queries
  - delegates to `eager_load` if joins are possible
  - if not, delegates to `preloads` api
  - works for first and second degree associations
  - `references` can be used to explicitly set the table to look for in an `includes` call if sometimes `ActiveRecord` craps out and can't find it
    - hashes can be used to shorten it
  - `joins`  is INNER JOIN in SQL
  - `find_or_create_by` is not atomic
    - it finds first then create by
  - `reset` will force the next access of a relational object to hit the database again
  - `extending` can allow you to append additional scoping from another module/s
  - `scope` and `unscope` can be used to add/remove prior scoping

# 5.7 Ignoring Columns
- can be set on the model to ignore columns `ignored_columns = ['col_a']`

# 5.8 Different Connections
- you can set different models to use different connections, i.e. for legacy dbs

# 5.9 Direct Database Connection
- you can use direct database connections to do stuff like executing raw queries
  - avoid if possible for security
  - `ActiveRecord::Base.connection.execute("show tables").values`
- various methods including `execute` , `delete` are available
- `raw_connection` will allow you to access connection for that specific DB type, like MYSQL or PostGres
  - should be avoided if possible to support cross DB code

