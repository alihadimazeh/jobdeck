class DashboardController < ApplicationController
  PREVIEW_LIMIT = 5

  # GET /
  # Every query goes through policy_scope like the other controllers' indexes, so narrowing a
  # role's scope later narrows the dashboard too (all scopes resolve to everything today).
  def show
    leads, jobs, orders = policy_scope(Lead), policy_scope(Job), policy_scope(Order)

    @due_today_count = leads.follow_up_due_today.count
    @due_today = leads.follow_up_due_today.includes(:customer).order(:id).limit(PREVIEW_LIMIT)

    # Longest-waiting first.
    @overdue_count = leads.follow_up_overdue.count
    @overdue = leads.follow_up_overdue.includes(:customer).order(:follow_up_date, :id).limit(PREVIEW_LIMIT)

    @active_jobs_count = jobs.active_status.count
    @active_jobs = jobs.active_status.includes(:customer).by_urgency.limit(PREVIEW_LIMIT)

    # Most overdue first; an invoice with no due date can't be late, so it goes last.
    @awaiting_payment_count = orders.awaiting_payment.count
    @awaiting_payment_total = orders.awaiting_payment.sum(:total)
    @awaiting_payment = orders.awaiting_payment.includes(:customer, :job)
                             .order(Order.arel_table[:due_date].asc.nulls_last).limit(PREVIEW_LIMIT)

    @to_bill_count = orders.to_bill.count
    @to_bill_total = orders.to_bill.sum(:total)
    @to_bill = orders.to_bill.includes(:customer, :job).order(:created_at).limit(PREVIEW_LIMIT)
  end
end
