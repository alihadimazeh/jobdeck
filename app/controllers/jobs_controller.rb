class JobsController < ApplicationController
  before_action :set_job, only: %i[ show edit update destroy ]

  # GET /jobs or /jobs.json
  def index
    @jobs = Job.includes(:customer)
  end

  # GET /jobs/1 or /jobs/1.json
  def show
  end

  # GET /jobs/new
  def new
    @job = Job.new
  end

  # GET /jobs/1/edit
  def edit
  end

  # POST /jobs or /jobs.json
  def create
    @job = Job.new(job_params)

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: "Job was successfully created." }
        format.json { render :show, status: :created, location: @job }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @job.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /jobs/1 or /jobs/1.json
  def update
    respond_to do |format|
      if @job.update(job_params)
        format.html { redirect_to @job, notice: "Job was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @job }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @job.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /jobs/1 or /jobs/1.json
  def destroy
    if @job.destroy
      respond_to do |format|
        format.html { redirect_to jobs_url, notice: "Job was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to jobs_url, alert: "Could not delete job.", status: :see_other
    end
  end

  private

  def set_job
    @job = Job.find(params.expect(:id))
  end

  def job_params
    params.expect(job: [ :title, :status, :job_type, :estimated_value, :assigned_to, :start_date, :end_date, :description, :customer_id, :address_line_1, :address_line_2, :city, :province, :postal_code ])
  end
end
