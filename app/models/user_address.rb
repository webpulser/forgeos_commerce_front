require File.join(Rails.plugins[:forgeos_commerce].directory,'app','models','user_address')
class UserAddress < Address

  Forgeos::CONFIG[:addresses]['mandatory_fields'].each do |fields|
    validates_presence_of fields
  end


  def to_s
     "#{I18n.t civility, :scope => [:civility, :label]} #{firstname} #{name} <br /> #{address} <br /> #{address_2} <br /> #{zip_code} #{city} <br />#{country.name.upcase}"
  end

  def designation
    self.class.to_s.underscore
  end

end
