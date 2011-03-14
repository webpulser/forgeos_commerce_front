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
    fields += '<div class="grid_5 password_field">'
    fields += form.label(password_field, t(:password).capitalize)
    fields += form.password_field(password_field)
    fields += "<div class=\"valid\">"
    fields += "<div class=\"right_password\"></div>"
    fields += "<div class=\"wrong_password\"></div>"
    fields += "</div>"
    fields += '</div>'
    fields += '<div class="grid_5">'
    fields += form.label(password_confirmation_field, t(:password_confirmation).capitalize)
    fields += form.password_field(password_confirmation_field)
    fields += "</div>"
    fields += "<script type=\"text/javascript\">
    $('#user_password').bind('keyup', function(){
      if ($(this).val().length > 6){
        $(this).addClass('right_password');
        $(this).removeClass('wrong_password');
      } else{
        $(this).addClass('wrong_password');
        $(this).removeClass('right_password');
      }
    });
    $('#user_password_confirmation').bind('keyup', function() {
      if($(this).val() == $('#user_password').val()){
        $(this).addClass('right_password');
        $(this).removeClass('wrong_password');
      } else{
        $(this).addClass('wrong_password');
        $(this).removeClass('right_password');
      }
    });
    </script>"
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
