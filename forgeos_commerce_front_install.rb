git :init
plugin 'engines', :git => 'git://github.com/lazyatom/engines.git'
append_file 'config/boot.rb', "require Rails.root.join('vendor','plugins','engines','boot')"

plugin 'attachment_fu', :git => 'git://github.com/technoweenie/attachment_fu.git'
plugin 'localized_dates', :git => 'git://github.com/clemens/localized_dates.git'
plugin 'open_flash_chart', :git => 'git://github.com/pullmonkey/open_flash_chart.git'
plugin 'forgeos_core', :git => '-b engines src.forgeos.com:forgeos/core', :submodule => true
plugin 'forgeos_cms', :git => '-b engines src.forgeos.com:forgeos/cms', :submodule => true
plugin 'forgeos_commerce', :git => '-b engines src.forgeos.com:forgeos/commerce', :submodule => true
plugin 'forgeos_commerce_front', :git => '-b engines src.forgeos.com:forgeos/commerce', :submodule => true

environment "config.plugins = [:forgeos_core, :all]"
gem 'acts-as-taggable-on'

route "map.page '/*url', :controller => 'pages', :action => 'show'"
route "map.connect ':controller/:action/:id.:format'"
route "map.connect ':controller/:action/:id'"
route "map.root :controller => 'pages', :action => 'index'"

rake 'db:create'
run './script/generate plugin_migration'
rake 'db:migrate'
rake 'forgeos:commerce_front:install'

run 'rm -rf config/locales/* public/*.html'
