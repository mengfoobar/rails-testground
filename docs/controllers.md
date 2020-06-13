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
- if route point to a static file, it will be directly served without using rack

# 4.3 Rendering unto View
- if no controller actions are specified, the `index.html` file gets rendered by default
- every controller has an implicit render call
- explicit rendering for views can be explicitly called by a controller if we want to preprocess or conditional render
- partials has `_` in front of it as convention, but calling is you still don't include it
- rendering html is supported but back practice due to security vulnerability
  - `render html: "<strong>Not Found</strong>".html_safe
  - the `safe` is required or else rails will complain
- controller helpers go into "app/helpers"
  - by default, all controllers includes all helpers (can be configured)
  - each view will have a default helper class in there
- javascript code that runs in browser `render js: <some js code>` is also supported
- render also supports `json:`, `xml:`
- if rails does not find a corresponding template to a user request (set in the mime/type), it will return `204 No Content` by default
- to render nothing, set the head method to return something to the user to indicate why. ex: `head :ok`
  - options hash can also be passed
- to not provide a layout in render, do `render layout: false`
  - the default is the layout responding to the controller method

# 4.4 Additional Layout Options
- layout can be set on the controller level
- can take either
  - string => points to a specific template name
  - symbol => calls a method which needs to return a string with a template name
  - true => returns argument error
  - false => do not use layout
  - optional:
    - :only => array of actions that this should be applied
    - :except => opposite of above

# 4.5 Redirecting
- redirect is often used instead of render because if render is used, and the user presesses back or reload, the user will be prompted to re-submit the form
- redirect types
  - 301 Moved Permanently: client should never explicitly load the old url, but always use the new one
  - 302 Moved Temporarily: client is redirected once, but still always use the old orl
  - 303 See Other: regardless of old url method (post, delete...etc), always use GET for the new url
  - 307 Temporariy Redirect: redirect once with same method as original request
- `redirect_to(target, response_status = {})` method
  - example: `redirect_to action: "show", id: 5`
  - flashes are possible with redirect
  - other ways to using `redirect_to`
  ``` ruby
  redirect_to action: "show", id: 5
  redirect_to @post
  redirect_to "http://www.rubyonrails.org"
  redirect_to "/images/screenshot.jpg"
  redirect_to posts_url
  redirect_to proc { edit_post_url(@post) }
  ```
- `redirect_back`
  - always good to add a fallback because browsers pulls location from HTTP_REFERRER header, and it's not always there

# 4.6 Controller/View Communcation
- controller pulls data to models, and passes it off to view via **instance variables**
- every instance variable belongs to the life of the controller object
- each instance variables from the controller objects are looped and copied to `ActionView::Base`

# 4.7 Action Callbacks
- pre, and post processing codes for actions
- can be **before**, **after**, **around**
- most of the call backs methods should be protected or private
  - external methods can be used as well
- can set instance variables to be used by controller actions
- can set multiple, and will run in sequence
- inheritance will execute action call backs down the chain (parent first, then child)
  - prepends can be used to run methods prior to callbacks inherited from a parent
    - i.e. `prepend_before_action`
  - `skip_` can be used to skip inherited callbacks
- `except` and `only` can be used to only apply callbacks for selected actions
- `before` and `around` can prevent controller action to be run by using `render` or `redirect_to`
  - for ex. can be used to block not authenticated users

# 4.8 Streaming
- setup a connection between client and server where data are sent continuously
- `ActionController:Live`
  - uses a socket
  - can included in controllers
  - header `Content-Type` should be set to specify `<dataformat>/event-stream`
  - a thread is opened for each stream
    - make sure it's closed after
  - supports Server-Sent Events (EventSource) on client side
  - great for chats and just general events streaming
- Templates streaming
  - layouts are rendered first, and streamed to client
  - this way, not all the layouts of a template needs to be rendered before client can view it
- `send_data` and `send_file` can be used to easily send large files to users
  - for `send_file`, don't do it for static files
    - best to copy to the public folder and serve it there
    - also be careful about the path, do not let user pass in params that allow them to get sensitive files served to them
  
  # 4.9 Variants
  - allows to modify request so that in the response, you can render different templates, data depending on desired variation (i.e. mobile vs desktop)
  ```ruby
    # before action
    request.variant = :mobile if request.user_agent =~ /iPhone/i

    #action
    respond_to do |format|
      format.html do |html|
        html.mobile do # renders app/views/posts/index.html+mobile.haml
          # some mobile only stuff
        end
      end
    end
    ....
  ```