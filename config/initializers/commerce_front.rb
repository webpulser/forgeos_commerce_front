# load settings
config_file = File.join(Rails.root, 'config', 'commerce.yml')
Forgeos::CONFIG = (File.exist?(config_file) ? YAML.load_file(config_file).symbolize_keys : {})
if not Forgeos::CONFIG[:multilang] and locale = Forgeos::CONFIG[:default_locale]
  I18n.available_locales = locale.to_a
end
