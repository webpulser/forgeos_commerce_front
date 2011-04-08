require File.join(Rails.plugins[:forgeos_commerce].directory,'app','models','user')
class User < Person
  validates_confirmation_of :email, :if => :confirm_email?

  def confirm_email?
    Forgeos::CONFIG[:account]['checkout_quick_create']
  end

  def skip_presence_of_lastname?
    not Forgeos::CONFIG[:account]['checkout_quick_create']
  end

  def skip_presence_of_firstname?
    not Forgeos::CONFIG[:account]['checkout_quick_create']
  end
end
