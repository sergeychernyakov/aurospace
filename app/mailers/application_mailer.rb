# frozen_string_literal: true

# app/mailers/application_mailer.rb

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('SMTP_USERNAME', 'noreply@aurospace.ru')
  layout 'mailer'
end
