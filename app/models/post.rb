class Post < ApplicationRecord
  belongs_to :user
  def content
    read_attribute(:content) + " lol"
  end
end
