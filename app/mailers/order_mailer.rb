# frozen_string_literal: true

# app/mailers/order_mailer.rb

class OrderMailer < ApplicationMailer
  def order_created(order)
    @order = order
    @user = order.user
    mail(to: @user.email, subject: "Order ##{order.id} created")
  end

  def payment_successful(order)
    @order = order
    @user = order.user
    mail(to: @user.email, subject: "Payment for Order ##{order.id} received")
  end

  def order_cancelled(order)
    @order = order
    @user = order.user
    mail(to: @user.email, subject: "Order ##{order.id} cancelled")
  end
end
