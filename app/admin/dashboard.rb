# frozen_string_literal: true

# app/admin/dashboard.rb

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { 'Dashboard' }

  content title: 'Dashboard' do
    # === Row 1: Charts ===
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
            li { strong { 'Total Orders: ' }; text_node total_orders.to_s }
            li { strong { 'Successful: ' }; text_node successful.to_s }
            li { strong { 'Total Revenue: ' }; text_node "#{revenue} RUB" }
            li { strong { 'Total Accounts: ' }; text_node total_accounts.to_s }
            li { strong { 'Total Balance: ' }; text_node "#{total_balance} RUB" }
          end
        end
      end
    end

    # === Row 2: Sidekiq + Queues ===
    columns do
      column do
        panel 'Sidekiq' do
          require 'sidekiq/api'
          stats = Sidekiq::Stats.new

          ul do
            li { strong { 'Processed: ' }; text_node stats.processed.to_s }
            li { strong { 'Failed: ' }; text_node stats.failed.to_s }
            li { strong { 'Enqueued: ' }; text_node stats.enqueued.to_s }
            li { strong { 'Scheduled: ' }; text_node Sidekiq::ScheduledSet.new.size.to_s }
            li { strong { 'Retry: ' }; text_node Sidekiq::RetrySet.new.size.to_s }
            li { strong { 'Dead: ' }; text_node Sidekiq::DeadSet.new.size.to_s }
            li { strong { 'Workers Busy: ' }; text_node Sidekiq::Workers.new.size.to_s }
          end

          h4 'Queues', style: 'margin-top: 12px; font-weight: 600;'
          ul do
            Sidekiq::Queue.all.each do |q|
              li { strong { "#{q.name}: " }; text_node "#{q.size} jobs (latency: #{q.latency.round(1)}s)" }
            end
            li { 'No queues' } if Sidekiq::Queue.all.empty?
          end
        rescue Redis::CannotConnectError
          para 'Redis/Sidekiq not available'
        end
      end
      column do
        panel 'Server Status' do
          # Memory
          rss_kb = `ps -o rss= -p #{Process.pid}`.strip.to_i
          rss_mb = (rss_kb / 1024.0).round(1)

          # CPU load
          load_avg = `sysctl -n vm.loadavg 2>/dev/null || cat /proc/loadavg 2>/dev/null`.strip

          # Disk
          disk = `df -h / 2>/dev/null`.split("\n").last&.split || []

          # Uptime
          uptime_sec = (Time.zone.now - File.stat("/proc/#{Process.pid}").mtime).round rescue nil # rubocop:disable Style/RescueModifier

          ul do
            li { strong { 'Ruby: ' }; text_node RUBY_VERSION }
            li { strong { 'Rails: ' }; text_node Rails.version }
            li { strong { 'PID: ' }; text_node Process.pid.to_s }
            li { strong { 'Memory (RSS): ' }; text_node "#{rss_mb} MB" }
            li { strong { 'Load Average: ' }; text_node load_avg.to_s }
            li { strong { 'Disk Used: ' }; text_node (disk[2] || 'N/A').to_s + ' / ' + (disk[1] || 'N/A').to_s }
            li { strong { 'Disk Available: ' }; text_node (disk[3] || 'N/A').to_s }
            li { strong { 'GC Count: ' }; text_node GC.count.to_s }
            li { strong { 'GC Heap Pages: ' }; text_node GC.stat[:heap_allocated_pages].to_s }
          end
        end
      end
    end

    # === Row 3: Database ===
    columns do
      column do
        panel 'Database Tables' do
          ActiveRecord::Base.connection.execute('ANALYZE')
          rows = ActiveRecord::Base.connection.exec_query(
            'SELECT relname AS table_name, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC',
          ).rows

          ul do
            rows.each do |row|
              li { strong { "#{row[0]}: " }; text_node row[1].to_s + ' rows' }
            end
          end
        rescue StandardError => e
          para "Unavailable: #{e.message}"
        end
      end
      column do
        panel 'Database Size' do
          db_name = ActiveRecord::Base.connection.current_database

          # Total DB size
          db_size = ActiveRecord::Base.connection.exec_query(
            "SELECT pg_size_pretty(pg_database_size('#{db_name}')) AS size",
          ).rows.first&.first

          # Table sizes
          table_sizes = ActiveRecord::Base.connection.exec_query(
            "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS size " \
            'FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10',
          ).rows

          # Connections
          connections = ActiveRecord::Base.connection.exec_query(
            'SELECT count(*) FROM pg_stat_activity',
          ).rows.first&.first

          ul do
            li { strong { 'Database: ' }; text_node db_name }
            li { strong { 'Total Size: ' }; text_node db_size.to_s }
            li { strong { 'Active Connections: ' }; text_node connections.to_s }
          end

          h4 'Table Sizes', style: 'margin-top: 12px; font-weight: 600;'
          ul do
            table_sizes.each do |row|
              li { strong { "#{row[0]}: " }; text_node row[1].to_s }
            end
          end
        rescue StandardError => e
          para "Unavailable: #{e.message}"
        end
      end
    end
  end
end
