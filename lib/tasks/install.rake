namespace :forgeos do
  namespace :commerce_front do
    task :sync => ['forgeos:commerce:sync'] do
      system "rsync -rvC #{File.join('vendor','plugins','forgeos_commerce_front','public')} ."
    end

    task :initialize => ['forgeos:commerce:initialize'] do
      rake "forgeos:core:generate:acl[#{File.join('vendor','plugins','forgeos_commerce_front')}]"
    end

    task :install => ['forgeos:commerce:install', :initialize, :sync]
  end
end
