Dir.glob(Rails.root.join('db', 'seeds', 'mock_data', '*.rb')).each do |seed_file|
  load seed_file
end
