namespace :schedule do
    desc "Daily"
    task :daily => :environment do
        if Time.now.day == 1
            Rake::Task["users:reset_monthly_allowance"].invoke
        end
    end
end
