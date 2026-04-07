# frozen_string_literal: true

# app/controllers/health_controller.rb
#
# Health check endpoints for Docker, Nginx, and monitoring.
#
# GET /up       - basic liveness (app is running)
# GET /health   - full readiness (app + DB + Redis)

class HealthController < ActionController::API
  # GET /up
  # Liveness probe: app process is running.
  # Used by Docker HEALTHCHECK and load balancers.
  def show
    render json: { status: 'ok' }, status: :ok
  end

  # GET /health
  # Readiness probe: app + all dependencies are working.
  # Used by deployment scripts and monitoring.
  def full
    checks = {
      app: 'ok',
      database: check_database,
      redis: check_redis,
    }

    healthy = checks.values.all? { |v| v == 'ok' }

    render json: {
      status: healthy ? 'ok' : 'degraded',
      checks: checks,
      timestamp: Time.zone.now.iso8601,
    }, status: healthy ? :ok : :service_unavailable
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    'ok'
  rescue StandardError => e
    "error: #{e.message}"
  end

  def check_redis
    Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')).ping
    'ok'
  rescue StandardError => e
    "error: #{e.message}"
  end
end
