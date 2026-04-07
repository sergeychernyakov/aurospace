# frozen_string_literal: true

# app/admin/dashboard.rb

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { 'Dashboard' }

  content title: 'AUROSPACE Dashboard' do
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
          data = Order.unscoped.successful.group_by_day(:paid_at, last: 30).sum(:amount_cents)
          line_chart data.transform_values { |v| v / 100.0 }, prefix: '', suffix: ' RUB'
        end
      end
      column do
        panel 'Summary' do
          attributes_table_for nil do
            row('Total Orders') { Order.unscoped.count }
            row('Successful') { Order.unscoped.successful.count }
            row('Total Revenue') { "#{Order.unscoped.successful.sum(:amount_cents) / 100.0} RUB" }
            row('Total Accounts') { Account.unscoped.count }
            row('Total Balance') { "#{Account.unscoped.sum(:balance_cents) / 100.0} RUB" }
          end
        end
      end
    end

    columns do
      column do
        panel 'Sidekiq' do
          require 'sidekiq/api'
          stats = Sidekiq::Stats.new
          attributes_table_for nil do
            row('Processed') { stats.processed }
            row('Failed') { stats.failed }
            row('Enqueued') { stats.enqueued }
            row('Retry') { Sidekiq::RetrySet.new.size }
            row('Workers Busy') { Sidekiq::Workers.new.size }
          end
        rescue Redis::CannotConnectError
          para 'Sidekiq/Redis is not available'
        end
      end
      column do
        panel 'Database' do
          tables = ActiveRecord::Base.connection.execute(
            'SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC',
          )
          table_for tables do
            column('Table') { |t| t['table'] }
            column('Rows') { |t| t['rows'] }
          end
        end
      end
    end
  end
end
