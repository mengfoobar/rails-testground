# CH 10 Action View

## 10.1 Layouts and Templates
- `applicaiton.html.erb` is inherited as base for all application controllers rendering
- `yield` keyword in templates loads corresponding view template for controller
  - keywords can be set using `content_for: <keyword>` to be used as `yield :left`
- use helper methods to clean up conditionarl rendering of html, and make it safer
- there are some special standard instance variables available to the views
  - `assigns` allows you to see data passing between controller-view
  - `controller` gets you controller name
  - `flash` to allow you to get the flash message from controller

## 10.2 Partials
- when you created shared partials, be careful about designs such as url path
- partials take implicitly variables available to parent
- partials can be rendered in collections as well
  - each partial gets access to the current index