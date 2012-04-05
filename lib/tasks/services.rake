# encoding: utf-8

namespace :services do
  task :run => :environment do
    trap "INT" do
      ServiceRunner.unsubscribe_all
      exit
    end

    # Require all services
    Dir[Rails.root.join("app/services/**/*.rb")].each {|f| require f}
    ServiceRunner.run_all
  end
end
