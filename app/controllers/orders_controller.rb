# frozen_string_literal: true

# app/controllers/orders_controller.rb

class OrdersController < ApplicationController
  def index
    orders = Order.where(user_id: params[:user_id]).order(created_at: :desc)
    render json: orders
  end

  def show
    order = Order.includes(:ledger_entries).find(params[:id])
    render json: order, include: [:ledger_entries]
  end

  def create
    user = User.find(params[:user_id])
    result = Orders::Create.new.call(
      user: user, amount_cents: params[:amount_cents].to_i, currency: params.fetch(:currency, 'RUB'),
    )
    handle_result(result, :created)
  end

  def pay
    order = Order.find(params[:id])
    payment_result = Yookassa::CreatePayment.new.call(order: order)

    case payment_result
    in Dry::Monads::Success(payment_data)
      start_result = Orders::StartPayment.new.call(
        order: order, payment_id: payment_data[:payment_id], confirmation_url: payment_data[:confirmation_url],
      )
      handle_result(start_result, :ok)
    in Dry::Monads::Failure(error)
      render_error(error, :unprocessable_entity)
    end
  end

  def cancel
    order = Order.find(params[:id])
    result = Orders::Cancel.new.call(order: order)
    handle_result(result, :ok)
  end

  private

  def handle_result(result, success_status)
    case result
    in Dry::Monads::Success(value)
      render json: value, status: success_status
    in Dry::Monads::Failure(error)
      render_error(error, :unprocessable_entity)
    end
  end

  def render_error(error, status)
    render json: { error: { code: error.to_s, message: error.to_s } }, status: status
  end
end
