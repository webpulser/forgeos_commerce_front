namespace :forgeos do
  task :assets, :roles => [:web, :app] do
    run "mkdir #{release_path}/tmp/attachment_fu;
         cd #{release_path}; rake forgeos:commerce_front:sync RAILS_ENV=production"
  end
end
