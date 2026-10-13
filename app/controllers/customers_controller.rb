class CustomersController < ApplicationController
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]
  def index
    @q = policy_scope(Customer).visible.ransack(params[:q])
    @pagy, @customers = pagy(@q.result(distinct: true).order(:id))
  end

  def show
    authorize @customer
  end

  def new
    @customer = Customer.new
    authorize @customer
  end

  def edit
    authorize @customer
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: "Customer was successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @customer
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: "Customer was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @customer
    if @customer.destroy
      respond_to do |format|
        format.html { redirect_to customers_url, notice: "Customer was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      @customer.archive!
      redirect_to customers_url, notice: "This customer has history and can't be deleted — archived instead.", status: :see_other
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email, :phone, :address_line_1, :address_line_2, :city, :province, :postal_code, :status, :notes)
  end
end
