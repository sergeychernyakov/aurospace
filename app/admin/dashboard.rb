# frozen_string_literal: true

# app/admin/dashboard.rb

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { 'Dashboard' }

  content title: 'Dashboard' do
    columns do
      column do
        panel 'Orders by Status' do
          pie_chart Order.unscoped.group(:status).count
        end
      end
      column do
        panel 'Orders per Day (Last 30 Days)' do
          line_chart Order.unscoped.group_by_day(:created_at, last: 30).count
        end
      end
    end

    columns do
      column do
        panel 'Revenue (Successful Orders)' do
          data = Order.unscoped.where(status: :successful).group_by_day(:paid_at, last: 30).sum(:amount_cents)
          line_chart data.transform_values { |v| v / 100.0 }, prefix: '', suffix: ' RUB'
        end
      end
      column do
        panel 'Summary' do
          total_orders = Order.unscoped.count
          successful = Order.unscoped.where(status: :successful).count
          revenue = Order.unscoped.where(status: :successful).sum(:amount_cents) / 100.0
          total_accounts = Account.unscoped.count
          total_balance = Account.unscoped.sum(:balance_cents) / 100.0

          ul do
            li "Total Orders: #{total_orders}"
            li "Successful: #{successful}"
            li "Total Revenue: #{revenue} RUB"
            li "Total Accounts: #{total_accounts}"
            li "Total Balance: #{total_balance} RUB"
          end
        end
      end
    end

    columns do
      column do
        panel 'Sidekiq' do
          require 'sidekiq/api'
          stats = Sidekiq::Stats.new

          ul do
            li "Processed: #{stats.processed}"
            li "Failed: #{stats.failed}"
            li "Enqueued: #{stats.enqueued}"
            li "Retry: #{Sidekiq::RetrySet.new.size}"
            li "Workers Busy: #{Sidekiq::Workers.new.size}"
          end
        rescue Redis::CannotConnectError
          para 'Sidekiq/Redis is not available'
        end
      end
      column do
        panel 'Database' do
          ActiveRecord::Base.connection.execute('ANALYZE')
          result = ActiveRecord::Base.connection.exec_query(
            'SELECT relname AS table_name, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC',
          )
          table_for result.rows do
            column('Table') { |row| row[0] }
            column('Rows') { |row| row[1] }
          end
        rescue StandardError => e
          para "Database stats unavailable: #{e.message}"
        end
      end
    end
  end
end
