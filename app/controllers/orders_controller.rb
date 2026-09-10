class OrdersController < ApplicationController
  before_action :set_job, only: [ :index, :new, :create ]
  before_action :set_order, only: [ :show, :edit, :update, :destroy ]

  # GET /jobs/:job_id/orders
  def index
    @orders = @job.orders.order(created_at: :desc)
  end

  # GET /orders/:id
  def show
  end

  # GET /jobs/:job_id/orders/new
  def new
    @order = @job.orders.build(customer: @job.customer)
  end

  # GET /orders/:id/edit
  def edit
  end

  # POST /jobs/:job_id/orders/
  def create
    @order = @job.orders.build(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /orders/:id
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: "Order was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /orders/:id
  def destroy
    @job = @order.job

    if @order.destroy
      respond_to do |format|
        format.html { redirect_to job_orders_path(@job), notice: "Order was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to job_orders_path(@job), alert: "Could not delete order.", status: :see_other
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.expect(order: [
      :status, :tax_rate, :issued_date, :due_date, :notes,
      line_items_attributes: [ [ :id, :item_type, :quantity, :unit, :unit_price, :description, :_destroy ] ]
    ])
  end
end
