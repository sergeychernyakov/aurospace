# frozen_string_literal: true

# app/admin/dashboard.rb
# rubocop:disable Metrics/BlockLength

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

    # === Row 2: Server Gauges ===
    columns do
      column do
        panel 'Server Status' do
          rss_kb = `ps -o rss= -p #{Process.pid}`.strip.to_i
          rss_mb = (rss_kb / 1024.0).round(1)
          mem_max = 1024.0 # assume 1GB max for gauge
          mem_pct = [(rss_mb / mem_max * 100).round, 100].min

          load_vals = `sysctl -n vm.loadavg 2>/dev/null`.strip.gsub(/[{}]/, '').split.map(&:to_f)
          load_1m = load_vals[0] || 0
          cores = `sysctl -n hw.ncpu 2>/dev/null`.strip.to_i
          cores = 4 if cores.zero?
          load_pct = [(load_1m / cores * 100).round, 100].min

          disk = `df -h / 2>/dev/null`.split("\n").last&.split || []
          disk_cap = disk[4]&.to_i || 0 # capacity percentage

          # Gauge CSS helper
          gauge_html = lambda { |label, value_text, pct, color|
            <<~HTML
              <div style="margin-bottom:16px;">
                <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
                  <span style="font-weight:600;font-size:13px;">#{label}</span>
                  <span style="font-size:13px;opacity:0.8;">#{value_text}</span>
                </div>
                <div style="background:rgba(255,255,255,0.1);border-radius:8px;height:20px;overflow:hidden;">
                  <div style="background:#{color};height:100%;width:#{pct}%;border-radius:8px;transition:width 0.5s;min-width:2px;"></div>
                </div>
              </div>
            HTML
          }

          mem_color = mem_pct > 80 ? '#ef4444' : mem_pct > 60 ? '#f59e0b' : '#22c55e'
          load_color = load_pct > 80 ? '#ef4444' : load_pct > 60 ? '#f59e0b' : '#22c55e'
          disk_color = disk_cap > 90 ? '#ef4444' : disk_cap > 70 ? '#f59e0b' : '#22c55e'

          div do
            text_node gauge_html.call('Memory (RSS)', "#{rss_mb} MB", mem_pct, mem_color).html_safe
            text_node gauge_html.call('CPU Load', "#{load_1m} / #{cores} cores", load_pct, load_color).html_safe
            text_node gauge_html.call('Disk', "#{disk[2] || '?'} / #{disk[1] || '?'} (#{disk_cap}%)", disk_cap, disk_color).html_safe
          end

          ul style: 'margin-top:12px;' do
            li { strong { 'Ruby: ' }; text_node "#{RUBY_VERSION} +YJIT" }
            li { strong { 'Rails: ' }; text_node Rails.version }
            li { strong { 'PID: ' }; text_node Process.pid.to_s }
            li { strong { 'GC: ' }; text_node "#{GC.count} runs, #{GC.stat[:heap_allocated_pages]} pages" }
          end
        end
      end
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
              li { strong { "#{q.name}: " }; text_node "#{q.size} jobs (#{q.latency.round(1)}s)" }
            end
            li { text_node 'No queues' } if Sidekiq::Queue.all.empty?
          end
        rescue Redis::CannotConnectError
          para 'Redis/Sidekiq not available'
        end
      end
    end

    # === Row 3: Database ===
    columns do
      column do
        panel 'Database Tables' do
          ActiveRecord::Base.connection.execute('ANALYZE')
          rows = ActiveRecord::Base.connection.exec_query(
            'SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC',
          ).rows

          ul do
            rows.each { |row| li { strong { "#{row[0]}: " }; text_node "#{row[1]} rows" } }
          end
        rescue StandardError => e
          para "Unavailable: #{e.message}"
        end
      end
      column do
        panel 'Database Size' do
          db_name = ActiveRecord::Base.connection.current_database

          db_size = ActiveRecord::Base.connection.exec_query(
            "SELECT pg_size_pretty(pg_database_size('#{db_name}'))",
          ).rows.first&.first

          table_sizes = ActiveRecord::Base.connection.exec_query(
            'SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) ' \
            'FROM pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10',
          ).rows

          connections = ActiveRecord::Base.connection.exec_query(
            'SELECT count(*) FROM pg_stat_activity',
          ).rows.first&.first

          ul do
            li { strong { 'Database: ' }; text_node db_name }
            li { strong { 'Total Size: ' }; text_node db_size.to_s }
            li { strong { 'Connections: ' }; text_node connections.to_s }
          end

          h4 'Table Sizes', style: 'margin-top: 12px; font-weight: 600;'
          ul do
            table_sizes.each { |row| li { strong { "#{row[0]}: " }; text_node row[1].to_s } }
          end
        rescue StandardError => e
          para "Unavailable: #{e.message}"
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
