class LeadsController < ApplicationController
  before_action :set_lead, only: %i[ show edit update destroy ]

  # GET /leads or /leads.json
  def index
    @q = Lead.ransack(params[:q])
    @pagy, @leads = pagy(@q.result(distinct: true).order(:id))
  end

  # GET /leads/1 or /leads/1.json
  def show
  end

  # GET /leads/new
  def new
    @lead = Lead.new
  end

  # GET /leads/1/edit
  def edit
  end

  # POST /leads or /leads.json
  def create
    @lead = Lead.new(lead_params)

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

  # DELETE /leads/1 or /leads/1.json
  def destroy
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
