class DashboardController < ApplicationController
  PREVIEW_LIMIT = 5

  # GET /
  def show
    @due_today_count = Lead.follow_up_due_today.count
    @due_today = Lead.follow_up_due_today.includes(:customer).order(:id).limit(PREVIEW_LIMIT)

    # Longest-waiting first.
    @overdue_count = Lead.follow_up_overdue.count
    @overdue = Lead.follow_up_overdue.includes(:customer).order(:follow_up_date, :id).limit(PREVIEW_LIMIT)

    @active_jobs_count = Job.active_status.count
    @active_jobs = Job.active_status.includes(:customer).order(:start_date).limit(PREVIEW_LIMIT)

    # Most overdue first; an invoice with no due date can't be late, so it goes last.
    @awaiting_payment_count = Order.awaiting_payment.count
    @awaiting_payment_total = Order.awaiting_payment.sum(:total)
    @awaiting_payment = Order.awaiting_payment.includes(:customer)
                             .order(Order.arel_table[:due_date].asc.nulls_last).limit(PREVIEW_LIMIT)

    @to_bill_count = Order.to_bill.count
    @to_bill_total = Order.to_bill.sum(:total)
    @to_bill = Order.to_bill.includes(:customer).order(:created_at).limit(PREVIEW_LIMIT)
  end
end
