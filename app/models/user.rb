load File.join(Gem.loaded_specs['forgeos_commerce'].full_gem_path, 'app', 'models', 'user.rb')
User.class_eval do
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
