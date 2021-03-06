# CH 17 Caching and Performance

## 17.1 View Caching
- page caching and action caching are often unlikely for apps that have personalization
  - i.e. if you need to login
  - fragment caching is the most likely hoice
- `caches_page`
  - rails caches entire reponse and serves is without involving the dispatcher
- `caches_action`
  - triggers the dispatcher, and goes through the callbacks on the controller so you can add some processing if needed
  - might be good way to expire cache in callbacks then just using `caches_page`
- Fragment Caching
  - performance not as mind blowing
    - still goes through dispatcher
    - a lot of the partial views can't really be cached so DB calls are still very likely
  - cache key are computed using the data objects fed into the view instead of the view itself
    - markdown on the view will not likely get cache busted
  - specified in the partial view templates
  - rails computes a call like `"get" "views/localhsot:3000/entries/d57823a936b2ee781687c74c44e056a0"` by computing a checksum of the partial
  - if the cache key was not present, a DB call would have been made
  - optional name can be set too to add additional path in the view within the view
  - if you want add others params (such as pagination) in the key, you can set them explictly
    - do DRY it up if you can
  - you can make a global fragment as well by just passing a symbol
- Russian-Doll caching
  - when you do nesting caching
    - i.e. the user partial has a list of posts -> cached, the post partials are cached as well
    - adding a new post would bust the cache for user, but only the new post needs to be rendered/cached
  - the parent object needs to be updated automatically when children for the cache to be recomputed
  - you need to set the `belongs_to: user, touch: true` in the child model so that when a new child is modified, the parent gets updated too
  - WTF: is the cache key not generated by hashing it's children but the model itself?
  - this strategy works because in most of the applications, it is read heavy
- Collection caching
  - when you want to render a collection of partials, this is useful
    - when rendering partial, rails loads, compiles, and renders each partial, extremely slow
    - this is not a problem if you are not using partial but instead put the html directly in the collection view
  - collection caching loads all of views at once assuming that each child entry is cached as well
  - cache key is computed using the cache keys of each child object
  - this is faster than fragment caching because fragment caching still reads and loads each fragment
  - https://blog.appsignal.com/2018/08/14/rails-collection-caching.html
- Conditional Caching
  - `cache_if` and `cache_unless`
- Expiration of cached content
  - expiration of keys using generation of code is called `generational caching`
    - it usually works 
  - Time-base expiry
    - you can set a time expiration on `expire_in: `
  - you can explictly expire fragment, page, and action as well
  - `Sweeper` classes lets you observe changes for a model, and you can then expire cache explictly
- `fragment_exist?` method lets you check to see if a fragment exists
- you can turn on cache logging to see what is being written, read

## 17.2 Data Caching
- you can easily write, read, delete object caches directly using `Rails.cache.<method>`

## 17.3 Web caching control
- you can set `expires_in` and `expires_now` on a cache to control the `Cache-Control` headers

## 17.4 etag
- for a view, you can use the `fresh_when` to compute an `etag`, and set the `last_modified` property to rendering completely if the data is fresh
- you can use `stale?` to verify if current view is fresh

