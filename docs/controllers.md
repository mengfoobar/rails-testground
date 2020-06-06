# Ch 4 - Working with Controllers

- controllers interact very closely with view layer

# 4.1 Rack

- ruby module that handles web requests
    - takes in a hash of environment params
    - returns [status_code, {<headers>}, [body of the request]]
- much of Action Controller is implemented as Rack middleware modules
    - for ex. there is a middleware that checks for migrations pending

## 4.1.1 Configuring Middleware

- can either add initializers or direction in `application.rb`
```ruby
 Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :patch, :put]
    end
  end
```

# 4.2 Action Displatch
- `ActionDispatch::Routing::RouteSet` routes the request based on paths set in `routes.rb`
```ruby
  get 'foo', to: 'foo#index'

  #will trigger
  FooController.action(:index).call
```

# 4.3 Rendering unto View