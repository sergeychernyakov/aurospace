# frozen_string_literal: true

# app/admin/webhook_events.rb

ActiveAdmin.register WebhookEvent do
  menu priority: 5

  scope_to(nil, association_method: :unscoped)
  controller do
    def scoped_collection
      WebhookEvent.unscoped
    end
  end

  actions :index, :show

  index do
    id_column
    column :provider
    column :event_type
    column :external_event_id
    column :status do |event|
      status_color = { 'pending' => 'orange', 'processed' => 'green', 'failed' => 'red' }
      status_tag event.status, class: status_color[event.status]
    end
    column :processed_at
    column :created_at
    actions
  end

  filter :provider
  filter :event_type
  filter :status
  filter :created_at

  show do
    attributes_table do
      row :id
      row :provider
      row :event_type
      row :external_event_id
      row :status do |event|
        status_color = { 'pending' => 'orange', 'processed' => 'green', 'failed' => 'red' }
        status_tag event.status, class: status_color[event.status]
      end
      row :processed_at
      row :discarded_at
      row :created_at
    end

    panel 'Payload' do
      pre JSON.pretty_generate(resource.payload || {})
    end
  end
end
