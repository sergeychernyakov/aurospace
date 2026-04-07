# frozen_string_literal: true

# app/admin/orders.rb

ActiveAdmin.register Order do
  menu priority: 2

  actions :index, :show

  includes :user

  scope_to(nil, association_method: :unscoped)
  controller do
    def scoped_collection
      Order.unscoped.includes(:user)
    end
  end

  index do
    id_column
    column :user, sortable: 'users.email' do |order|
      order.user&.email
    end
    column :amount do |order|
      number_to_currency(order.amount_cents / 100.0, unit: '', precision: 2) + " #{order.currency}"
    end
    column :status do |order|
      status_color = { 'created' => 'blue', 'payment_pending' => 'orange',
                       'successful' => 'green', 'cancelled' => 'red', }
      status_tag order.status, class: status_color[order.status]
    end
    column :paid_at
    column :created_at
    actions
  end

  filter :status, as: :select, collection: Order.statuses
  filter :user
  filter :amount_cents
  filter :created_at

  show do
    attributes_table do
      row :id
      row :user do |order|
        order.user&.email
      end
      row :amount do |order|
        number_to_currency(order.amount_cents / 100.0, unit: '', precision: 2) + " #{order.currency}"
      end
      row :status do |order|
        status_color = { 'created' => 'blue', 'payment_pending' => 'orange',
                         'successful' => 'green', 'cancelled' => 'red', }
        status_tag order.status, class: status_color[order.status]
      end
      row :payment_provider
      row :external_payment_id
      row :paid_at
      row :cancelled_at
      row :discarded_at
      row :created_at
      row :updated_at
    end

    panel 'Ledger Entries' do
      entries = LedgerEntry.where(order_id: order.id).order(created_at: :asc)
      table_for entries do
        column :id
        column :entry_type do |entry|
          entry_color = { 'credit' => 'green', 'debit' => 'orange', 'reversal' => 'red' }
          status_tag entry.entry_type, class: entry_color[entry.entry_type]
        end
        column :amount do |entry|
          number_to_currency(entry.amount_cents / 100.0, unit: '', precision: 2) + " #{entry.currency}"
        end
        column :reference
        column :created_at
      end
    end
  end

  member_action :cancel_order, method: :post do
    order = Order.unscoped.find(params[:id])
    result = Orders::Cancel.new.call(order: order)
    case result
    in Dry::Monads::Success(_)
      redirect_to a_order_path(order), notice: 'Order cancelled successfully.'
    in Dry::Monads::Failure(error)
      redirect_to a_order_path(order), alert: "Cannot cancel order: #{error}"
    end
  end

  action_item :cancel, only: :show do
    if resource.successful?
      link_to 'Cancel Order', cancel_order_a_order_path(resource), method: :post,
                                                                   data: { confirm: 'Are you sure?' }
    end
  end
end
