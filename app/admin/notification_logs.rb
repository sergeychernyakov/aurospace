# frozen_string_literal: true

# app/admin/notification_logs.rb

ActiveAdmin.register NotificationLog do
  menu priority: 6

  includes :order

  scope_to(nil, association_method: :unscoped)
  controller do
    def scoped_collection
      NotificationLog.unscoped.includes(:order)
    end
  end

  actions :index, :show

  index do
    id_column
    column :order
    column :mail_type
    column :recipient
    column :sent_at
    column :created_at
    actions
  end

  filter :mail_type
  filter :sent_at
  filter :created_at

  show do
    attributes_table do
      row :id
      row :order
      row :mail_type
      row :recipient
      row :sent_at
      row :discarded_at
      row :created_at
    end
  end
end
