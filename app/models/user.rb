class User < ActiveRecord::Base
  attr_accessible :email, :name

  after_create do
    Activity.publish "user:created", self
  end
  after_update do
    Activity.publish "user:updated", self
  end
  after_destroy do
    Activity.publish "user:destroyed", self
  end
end
