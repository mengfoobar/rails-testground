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

# CH 7.5 Many-to-Many Relationships

## CH 7.5.1 has_and_belongs_to_many
- good for simple joins but not great if you want to attach additional data to join table
  - attributes from join table are read-only
```ruby
class CreateBillingCodesTimesheets < ActiveRecord::Migration
  def change
    create_join_table :billing_codes, :timesheets do |t|
      t.index [:billing_code_id, :timesheet_id]
      t.index [:timesheet_id, :billing_code_id]
  end
end

class Timesheet < ActiveRecord::Base
  has_and_belongs_to_many :billing_codes
end

class BillingCode < ActiveRecord::Base
  has_and_belongs_to_many :timesheets
end
```
- `create_join_table` is a special migration api that takes care of creating join table
-  self-referential many to many can be done as well but its a bit tricky

## CH 7.5.2 has_many :through

```bash
rails generate model Physician name:string
rails generate model Patient name:string
rails generate model Appointment physician_id:integer patient_id:integer appointment_date:datetime
```

```ruby
class Appointment < ApplicationRecord
  belongs_to :physician
  belongs_to :patient
end

class Patient < ApplicationRecord
  has_many :appointments
  has_many :physicians, through: :appointments
end

class Physician < ApplicationRecord
  has_many :appointments
  has_many :patients, -> { distinct }, through: :appointments #distinct will get only uniq patients
end
```
- you can not create a child record through the through record
  - the child record needs to be created first, then added
- you can validate uniqueness via `validates_uniqueness_of :physician_id, scope: :patient_id`
  - would check each patient only have one physician

# CH 7.6 One-to-One Relationships
- similar to `has_many` but limits to one
- the parent should always add a `destroy` method
- can be used along wiht `has_many` and act as a scope
  - used to get stuff like latest, primary
  - will grab the first one if there are multiple results


