class LeadsController < ApplicationController
  before_action :set_lead, only: %i[ show edit update destroy reschedule ]

  # GET /leads or /leads.json
  def index
    @q = policy_scope(Lead).ransack(params[:q])
    @pagy, @leads = pagy(@q.result(distinct: true).includes(:customer).order(:id))
  end

  # GET /leads/1 or /leads/1.json
  def show
    authorize @lead
  end

  # GET /leads/new
  def new
    @lead = Lead.new
    authorize @lead
  end

  # GET /leads/1/edit
  def edit
    authorize @lead
  end

  # POST /leads or /leads.json
  def create
    @lead = Lead.new(lead_params)
    authorize @lead

    respond_to do |format|
      if @lead.save
        format.html { redirect_to @lead, notice: "Lead was successfully created." }
        format.json { render :show, status: :created, location: @lead }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @lead.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /leads/1 or /leads/1.json
  def update
    authorize @lead
    respond_to do |format|
      if @lead.update(lead_params)
        format.html { redirect_to @lead, notice: "Lead was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @lead }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @lead.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH /leads/1/reschedule
  # The dashboard's per-row follow-up reschedule. Answers with a Turbo Stream that drops the row
  # from whichever follow-up card it was on and refreshes that card's count.
  def reschedule
    authorize @lead, :update?

    @date = begin
      Date.iso8601(params[:follow_up_date].to_s)
    rescue Date::Error
      nil
    end
    unless @date
      respond_to do |format|
        format.turbo_stream { render :reschedule, status: :unprocessable_content }
        format.html { redirect_back_or_to root_path, alert: "Pick a date to reschedule to.", status: :see_other }
      end
      return
    end

    # Checked before the update: after it, the lead may be on neither card.
    scope = policy_scope(Lead)
    was_due_today = scope.follow_up_due_today.exists?(@lead.id)
    was_overdue = scope.follow_up_overdue.exists?(@lead.id)

    @lead.update!(follow_up_date: @date)
    @due_today_count = scope.follow_up_due_today.count if was_due_today
    @overdue_count = scope.follow_up_overdue.count if was_overdue

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to root_path, notice: "Follow-up moved to #{helpers.format_date(@date)}.", status: :see_other }
    end
  end

  # DELETE /leads/1 or /leads/1.json
  def destroy
    authorize @lead
    if @lead.destroy
      respond_to do |format|
        format.html { redirect_to leads_url, notice: "Lead was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to leads_url, alert: "Could not delete lead.", status: :see_other
    end
  end

  private

  def set_lead
    @lead = Lead.find(params.expect(:id))
  end

  def lead_params
    params.expect(lead: [ :title, :status, :job_type, :source, :estimated_value, :assigned_to, :description, :follow_up_date, :customer_id ])
  end
end
