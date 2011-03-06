module ApplicationHelper

  def display_avatar(avatar, thumb=:small)
    if avatar and not avatar.new_record?
      image_tag(avatar.public_filename(thumb))
    else
      image_tag('front/blank-avatar.jpg')
    end
  end

  def password_fields(form, options={})
    password_field = options[:password_field] || :password
    password_confirmation_field = options[:password_confirmation_field] || :password_confirmation
    fields =  ''
    fields += form.label(password_field, t(:password))
    fields += form.password_field(password_field)
    fields += '<br />'
    fields += form.label(password_confirmation_field, t(:password_confirmation))
    fields += form.password_field(password_confirmation_field)
    fields += '<br />'
    fields += "<div class=\"validchamp\">"
    fields += "<div class=\"right_password\">"
    fields += image_tag('commerce_front/infos/right.png')
    fields += "<div class=\"wrong_password\">"
    fields += image_tag('commerce_front/infos/false.png')
    fields
  end

  def options_for_countries(value)
    iso_codes = Forgeos::CONFIG[:addresses]['available_countries']
    iso_code = Forgeos::CONFIG[:addresses]['default_country']
    default_country = Country.first(:select => :id, :conditions => { :iso => iso_code})
    default_country_id = (default_country ? default_country.id : nil)
    countries = Country.all(:conditions => {:iso => iso_codes}, :select => 'id,printable_name', :order=>'printable_name')
    options_from_collection_for_select(countries, :id, :printable_name, (value.nil? ? default_country_id : value))
  end
end
