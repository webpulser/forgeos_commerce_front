module ApplicationHelper

  def display_avatar(avatar, thumb=:small)
    if avatar and not avatar.new_record?
      image_tag(avatar.public_filename(thumb))
    else
      image_tag('front/blank-avatar.jpg')
    end
  end

  def password_fields(form, options={})
    base_options = {
      :password_field => :password,
      :confirmation_field => :password_confirmation,
      :password_label => t(:password),
      :confirmation_label => t(:password_confirmation).capitalize,
      :label_class => '',
      :input_class => '',
      :field_class => 'grid_5',
    }
    opts = base_options.merge(options)
    password_field = opts[:password_field]
    confirmation_field = opts[:confirmation_field]

    fields =  ''
    fields += "<div class='#{opts[:field_class]} password_field'>"
    fields += "<div class='#{opts[:label_class]} password_field'>"
    fields += form.label(password_field, opts[:password_label])
    fields += '</div>'
    fields += "<div class='#{opts[:input_class]} password_field'>"
    fields += form.password_field(password_field)
    fields += '</div>'
    fields += '</div>'
    fields += "<div class='#{opts[:field_class]} password_field'>"
    fields += "<div class='#{opts[:label_class]} password_field'>"
    fields += form.label(confirmation_field, opts[:confirmation_label])
    fields += "</div>"
    fields += "<div class='#{opts[:input_class]} password_field'>"
    fields += form.password_field(confirmation_field)
    fields += "</div>"
    fields += "</div>"
    fields += "<script type=\"text/javascript\">
    $('#user_password').bind('keyup', function(){
      if ($(this).val().length > 5){
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
