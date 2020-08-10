# CH 20 Ajax on Rails

- AJAX enables behavioral changes on web pages without normal http request life cycle (aka page refresh)
- unobtrusive javascript generally means using css selectors to add behavior to dom instead of adding event handlers on element attributes
  - ideally this allows your webpage to work to an extent even if the user do not enable javascript
- will use an example using `form_for`, which is a form that submits ajax call

```html.erb
...
<%= form_with model: User.new, data: {'js-new-user-form' => true} do |form| %>
  Name <%= form.text_field :name %><br>
  Email <%= form.text_field :email %><br>

<% end %>
...
```
- the above erb will generate the following:

```html
<form data-js-new-user-form="true" action="/user" data-remote="true" method="post">
```
- the `remote` will indicate to rails to submit an ajax call vs a regular call
- now the rails code for handling on server:

```ruby
# on controllers/user.rb
def create
  @user = User.new(params[:user].permit(:name, :email))
  if @user.save
    render partial: "new_user_created", locals: {user: @user}
  end
```
- finally, we need to add some unobtrusive javascript to update the view
```javascript
$(document).ready(function(){
  $('[data-js-new-user-form]').on("ajax:success", function(event, data, status, xhr){
    $('#tutorials').append(xhr.responseText)
  })
})

```