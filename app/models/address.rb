class Address < ActiveRecord::Base
      
  def initialize(*params)
    super(*params)
    #if @new_record && params == [{}]
    self.form_attributes = {} if self.form_attributes.nil?
    #end
  end
  
  def form
    return Form.find_by_model('Address')
  end
  
  def valid?
    if super
      if self.form
        self.form.form_attributes.all(:conditions => {:attributes_forms => {:validate => true}}).each do |form_attribute|
          return false if self.form_attributes[form_attribute.access_method].blank?
        end
      else
        return true
      end
      return true
    else
      false  
    end
  end
end