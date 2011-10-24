require 'forgeos/commerce/engine'
require 'forgeos/cms_front/engine'

module Forgeos
  module CommerceFront
    class Engine < Rails::Engine
      paths["config/locales"] << 'config/locales/**'
    end
  end
end
