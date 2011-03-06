require 'forgeos_commerce_front'
Forgeos::CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'commerce.yml')).symbolize_keys
# load settings
if not Forgeos::CONFIG[:multilang] and locale = Forgeos::CONFIG[:default_locale]
  I18n.available_locales = locale.to_a
end

puts 'Forgeos Commerce Front loaded'
