# Ch 9 Advanced Active Record

## 9.1 Scope
- enables you to define and chain query criteria in a way you can easily access
- you can add parameters to scopes as well
```ruby
def self.delinquent
  where('timesheets_updated_at < ?', 1.week.ago)
end

BillableWeek.newer_than(Date.today)
```
- chaining can be used within scopes as well
- chaining on `has_many` associations can be used as well
- joins can be used within scoping
```ruby
scope :tardy, -> {
  joins(:timesheets).
  where("timesheets.submitted_at <= ?", 7.days.ago).
  group("user.id")
}
```
- just joining like above is bad because we have timesheet logic in there
  - we can use merge to avoid this
```ruby
#on Timesheet
scope :late, -> { where("timesheet.submitted_at <= ?", 7.days.ago) }

# on user
scope :tardy, -> {
  joins(:timesheets).group("user.id").merge(Timesheet.late)
}
```
- `default_scope` can be used to apply filters on all find queries
  - will be overwritten if you specify your own conditions
  - `unscoped` can be used to not use `default_scope`
  - when you create, your default scope params will be applied
- doing create on a scope will create with all the scope params
```ruby
scope :perfect, -> { submitted.where(total_hours: 40) }

#running the following will create with submitted=true, and total_hours = 40
Timesheet.perfect.build
```

## 9.2 Callbacks
- allows you to add behaviors to different parts of a model's life cycle
- callback methods should be in the form of either
  - one liners
  - declaration block
  - private/protected methods
- available callbacks includes:
  - matching before and afters
    - `before_validation`, `after_validation`
    - `before_save`, `around_save`
    - `before_create`, `after_create`
    - `before_update`, `after_update`
    - `before_destroy`, `after_destroy`
  - around operations
    - `around_save`
    - `around_create` 
- you can set callbacks on specific model actions
  - `before_validation :some_callback, on: :create`
- callbacks can be set on `transactions` as well
  - `after_commit`
  - `after_rollback`
  - `after_touch`
- to halt a callback chain, `throw(:abort)` needs to be called
- common uses of callbacks
  - clean/populate derived attributes before validation
- 
- `after_initialize` allows you to add behavior without messing around with default initialize methods of models
  - can use `new_record?` attribute to determine if it's a new record
- `serialize` 
  - allows data stored as YAML for a column to come out as either JSON, an object, Hash
  - `after_initialize` can be used to set default values
  - `store` is also an option to set default values
- callback classes can be used to reuse callback methods for multiple models without instantiation
- you can create a plugin if multiple methods of a callback class are used in more than one model to DRY it up

## 9.3 Attributes API
- `attributes(name, cast_type, options)`
- can be used to type cast input values to a type in active record
  - to and from DB
- default value can be set as well
- a custom attribute can be set and registered via `ActiveRecord::Type.register`
  - ex. converting percentage rating into stars

## 9.4 Serialized Attributes
- `store` is generally used over `serialize`
- `store` will allow you to set a field as either JSON, or default YAML
  - you can then get and set nested values in that field
- if you are using Postgresql, you can store things as documents directly as JSON in a column
  - each field can then be set as arrays and be queried with same performance as MongoDB
  - no need to serialize or use `store`, it can just be accessed

```ruby
class User < ActiveRecord::Base
  store :settings, accessors: [:color, :homepage], coder: JSON
  store :parent, accessors: [:name], coder: JSON, prefix: true
end

user.color = "red" #no prefix, saved in column settings as yaml
user.parent_name # has prefix, stored in parent column
```
## 9.5 Enums
- stored as integers in DB, but abstracted into attributes in rails
```ruby
class Post < ApplicationRecord
  enum status: %i(draft published archived)
  ...
end

post.draft?
post.publised?
post.status # "draft"
```
- scoping works as well
- make to add prefix and suffix if there are to be collisions

## 9.6 Secure Tokens
- rails supports built in token generation method
  - can specify column name as well
- `has_secure_token :auth_token`

## 9.7 Calculation Methods
- cauculate methods allow you to perform aggregation queries in DB
- performed on `ActiveRecord::Relation` models
- `pluck` is performed as a SQL query
  
## 9.8 Batch Operations
- bulk **Inserts**
  - one option to insert a lot is:
    - do a batch at a time by using the `INSERT INTO` statement
      - faster but do not have access to ActiveRecord hooks, validations
    - insert one at a time by creating a ActiveRecord instance
      - a lot slower but has access to ActiveRecord hooks/validations
  - Postgres' `COPY FROM` extention allows you import from a CSV directly
- bulk **Reads**
  - `find_each` batches read a set amount from DB at a time in sequence
    - can increment start id using `being_at` 
    - will load ActiveRecord objects in memory
  - `find_in_batches` is similar to `find_each` but returns arrays
  - `in_batches` will return `ActiveRecord::Relation` object
    - won't load in memory
    - good for stuff like `delete_all`
- bulk **updates**
  - `update_all` option or load them in memory and update individually
- bulk **deletes**
  - `delete_all` will delete via sql query while `destroy_all` will load each model into memory
    - `destroy_all` is slower but will trigger callbacks
  - `destroy_all` will delete associations as well if `dependent: :destroy` is set
    - if dependent option is not set, it will just nullify the association parent column field
  - `person.registration.delete_all` does not work
    - need to use `Registration.where(person_id: perosn.id).delete_all`
  
## 9.9 Single-Table Inheritance
- allows you to use one table to achieve polymorphism
- helps you adhere to the *open-closed principle* in **SOLID**
- need to add a `type` column to the table
  - handled by rails implictly
  - value will return inherited class name
- unique attributes will be null for other inherited models
  - generally good idea to avoid too many unique attributes
- careful about relations with other models inheriting the same model
  - queries won't be able to distinguish which is which

## 9.10 Abstract Classes
- by setting `self.abstract_class = true` on the model, ActiveRecord won't look for the table in sql
  - you can then write methods for a class and have inherited models access it

## 9.11 Polymorphic has_many Relationships
- will need to add a column on a model with an attribute `polymorphic: true` to allow the model to belong to many models
  - i.e. for `comments` -> `t.references :commentable, polymorphic: true`
  - this allows rails to distinguish which comments belong to which model
  - it's implicitly handled
- using it with `has_many` through is a bit tricky
  - will need to use `source` and `source_type` attribute to help rails distinguish between models

## 9.12 Foreign-key Constraints
- specifying foreign key explicitly will be really useful when you want to enforce relational integrity in the db level
  - for ex, if someone else runs SQL `delete_all` on the parent model, which means your child objects will be missing references
- migration example: `add_foreign_key :auctions, :users`

## 9.13 Modules for Reusing Common Behavior
- ruby lets you add methods to classes at any time during runtime
```ruby
class Foo < ActiveRecord::Base
  has_many :bars
end

class Foo < ActiveRecord::Base
  belongs_to :spam
end
```
- if there are associations that are to be used in many models, you can put it in a module using the `included` api, and extend them

## 9.14 Value Objects
- models objects are mutable, but value objects are not
- you shouldn't compare if you model objects are equal too because they should be different by nature
- in these cases, value objects should be created
  - they are immutable
  - equal if all of the attributes are equal
  - do not inherit from `ActiveRecord::Base` but instead just ruby object

## 9.15 Non-persisted Models
- if you just want a object to temporarily store data without persisting, you can use the `ActiveModel::Model` mixin

## 9.17 PostgresSQL
- supports array column types
  - querible
- ranges
  - daterange, time range most common
- JSON type
  - querible
- different kinds of indexes optimized for different data types
  - JSON has a special type