require './twitty'

ENVIRONMENT = ARGV[0] || 'development'

def process_main
  Twitty.new(ENVIRONMENT).refresh_main_data
end

process_main
