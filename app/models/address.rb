load File.join(Gem.loaded_specs['forgeos_core'].full_gem_path, 'app', 'models', 'address.rb')
Address.class_eval do
  attr_reader :form, :form_attributes

  before_save :check_form_attributes

  def initialize(*params)
    super(*params)
    @form_attributes = {} unless form_attributes
    @form = Form.find_by_model('Address')
  end

  def check_form_attributes
    form.form_attributes.all(:conditions => {:attributes_forms => {:validate => true}}).each do |form_attribute|
      errors.add(form_attribute.access_method, I18n.t('activerecord.errors.messages.blank')) if form_attributes[form_attribute.access_method].blank?
    end
  end
end
