load File.join(Gem.loaded_specs['forgeos_commerce'].full_gem_path, 'app', 'models', 'user_address.rb')
UserAddress.class_eval do

  if Forgeos::CONFIG[:addresses] and mandatory_fields = Forgeos::CONFIG[:addresses]['mandatory_fields']
    validates *mandatory_fields, :presence => true
  end

  def to_s
     "#{I18n.t civility, :scope => [:civility, :label]} #{firstname} #{name} <br /> #{address} <br /> #{address_2} <br /> #{zip_code} #{city} <br />#{country.name.upcase}"
  end

  def designation
    self.class.to_s.underscore
  end
end
