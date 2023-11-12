# Put any seed scripts that need to be run into db/seeds to automatically
# run the script when bundle exec rake db:seed is called
Dir.glob(Rails.root.join('db', 'seeds', '*.rb')).each do |seed_file|
  load seed_file
end
