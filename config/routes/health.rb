# frozen_string_literal: true

# config/routes/health.rb
#
# Health check routes.
# Include in main routes.rb: draw(:health)

get '/up',     to: 'health#show'
get '/health', to: 'health#full'
