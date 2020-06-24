# CH 7 Active Record Associations

# Setup
```bash
rails generate model User handle:string email:string
rails generate migration AddUserToPost
# refer to migration file
```

# CH 7.1 Association Hierarchy

- objects returned from associations methods are `ActiveRecord::Associations::CollectionProxy []>`

# CH 7.2 One-to-Many Relationships
- Rails can’t be trusted to maintain referential integrity
  - add foreign key constraint in addition to a reference to ensure this is respected
- refer to `AddUserRefToProducts` for migration file example
- adding objects to association is easy as:
```ruby
  user.posts << Post.new(...)
```
- associations are cached unless you `.reload`

# CH 7.3 Belongs to Associations
- an object belongs to another if it has the foreign key column
- set as follows:
```ruby
class Post < ApplicationRecord
  belongs_to :user
  ...
end
```
- can set custom names with scoping
```ruby
class Timesheet < ActiveRecord::Base
  belongs_to :approver, 
    -> { where(approver: true) },
    class_name: 'User'

  belongs_to :user
end
```
  - be aware that setting scope does not affect the assignment. You have to save, then reload for it to be read
- foreign keys can be set explicitly


# CH 7.4 Has Many Associations
- `<< (*records)` and `create(attributes = {})` both work on one and many
  - these will also trigger `:before_add` and `:after_add` call backs
  - NTS check: does this assign foreign key automatically?
- `create(attributes, &block)` will create new record and set foreign key attribute correctly
  - does not trigger `after_add`
- `delete` and `delete_all` defaults to just setting foreign key to null
  - to actually remove, set the `:dependent` option
- `destroy` will remote child records with individual DELETE statements. It will also load records in memory and execute call backs to be careful
- `includes` will eager load specified children of the associated objects
  - removes n+1 queries when retrieving children of associate objects

```ruby
class Timesheet < ActiveRecord::Base
  has_many :billable_weeks, -> { includes(:billing_code) }
end
```