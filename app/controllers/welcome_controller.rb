class WelcomeController < ApplicationController

  def index
    @text = helpers.get_fun_stuff 
  end
end
