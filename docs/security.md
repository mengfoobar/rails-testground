# CH 15 Security

- best way to be a secure developer is to understand the common attack vectors and learn how to avoid them

## 15.1 Password Management
- simplest way to store password is to hash it with SHA1 then compare user inputted password hash with the one that is stored
  - however, this does not protect against rainbow dictionary
- adding a salt to the password before hashing will have better protection than just hashing the password
  - ideally salt is randomly generated for every password, and stored separatly
- use third party gem if possible
- if not, use bcrypt, which makes it much slower to decrypt passwords


## 15.2 Log Masking
- rails will autolog all the request parameters
- `password` and `password_confirmation` params are automatically redacted
- to redact more, edit `Rails.application.config.filter_parameters += [:password]`

## 15.3 SSL
- adding SSL to your network will prevent others from listening in
- set `config.force_ssl = true` to force all access to redirect to HTTPS
- this can be set in a granular level as well

## 15.4 Model Mass-Assignment Attributes Protection
- pass assignment for certain models is highly dangerous
  - for ex. `User.create(params[:user])` someone might pass in say `admin: true`, which would give someone admin permission even though they shouldn't 
- you can use `require` combined with `permit` to only allow certain params

```ruby
class UsersController < ApplicationController
  def create
    user = User.create!(create_params)
    redirect_to user
  end

  private

  def create_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

## 15.5 SQL Injection
- happens that malicious fragments of SQL code gets inputted to the application
```ruby
def search
  @products = Product.where("name LIKE '%#{params[:search_terms]}%'")
end

# if params[:search_terms] was   ~    %';DELETE FROM users;%      ~,
# then the full SQL query becomes

SELECT * from products WHERE name LIKE '%'; DELETE FROM users;%';
```
- rule of thumb, never directly inject user's input
- use variable substitution provided by ActiveRecord

```ruby
@products = Product.where('name LIKE ?', "%#{params[:query]}%")
```
- ActiveRecord will automatically add quotation in the way that it's safe

## 15.6 XSS Cross-Site Scripting
- Same Origin Policy
  - policy that allows on website from reading/writing from another
  - checks protocal, host, and port
  - however, if the javacript is executed on client side of the same origin, it is an issue
- when client-side javascript code is injected into the app
  - this is often done by a malicious url with a script tag as the value of a parameter
  - dangerous code can also be injected into the database
    - for ex someone adding a harmful comment on a video
- most of the texts from rails are often escaped by default when the client sends them to rails
  - you have to set `html_unsafe` explicitly to navigate around it
- you want to escape on rendering (output)


## 15.7 XSRF Cross-Site Request Forgery
- when one domain is forging request from another 
- CSRF tokens are generated per app to prevent non allowed clients
- SOP does not prevent the execution of CSRF
  - making request is okay from a non same origin client which is still bad
  - (reading responses are not)
-  For updates, make sure to use NON Get calls
   -  this will prevent any link clicking attacks if hackers were able to inject links into your page
-  Rails has `protect_from_forgery` option on `ApplicationController` that will add a security token to any page it renders
   -  this token will be verified when a request is made to make sure it's coming from the same place
