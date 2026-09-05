class QuotesController < ApplicationController
  before_action :set_lead,  only: %i[ index new create ]
  before_action :set_quote, only: %i[ show edit update destroy accept ]

  # GET /leads/:lead_id/quotes
  def index
    @quotes = @lead.quotes.order(created_at: :desc)
  end

  # GET /quotes/:id
  def show
  end

  # GET /leads/:lead_id/quotes/new
  def new
    @quote = @lead.quotes.build(customer: @lead.customer)
    @quote.rooms.build
  end

  # GET /quotes/:id/edit
  def edit
  end

  # POST /leads/:lead_id/quotes
  def create
    @quote = @lead.quotes.build(quote_params)
    @quote.customer = @lead.customer

    respond_to do |format|
      if @quote.save
        format.html { redirect_to @quote, notice: "Quote was successfully created." }
        format.json { render :show, status: :created, location: @quote }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @quote.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /quotes/:id
  def update
    respond_to do |format|
      if @quote.update(quote_params)
        format.html { redirect_to @quote, notice: "Quote was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @quote }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @quote.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH /quotes/:id/accept
  def accept
    @quote.update!(status: :accepted)
    redirect_to @quote, notice: "Quote accepted — job created."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @quote, alert: e.record.errors.full_messages.to_sentence
  rescue => e
    redirect_to @quote, alert: "Could not convert this quote to a job: #{e.message}"
  end

  # DELETE /quotes/:id
  def destroy
    @lead = @quote.lead

    if @quote.destroy
      respond_to do |format|
        format.html { redirect_to lead_quotes_path(@lead), notice: "Quote was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to lead_quotes_path(@lead), alert: "Could not delete quote.", status: :see_other
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def quote_params
    params.expect(quote: [
      :status, :tax_rate, :issued_date, :valid_until, :notes,
      rooms_attributes:            [ [ :id, :name, :length, :width, :notes, :_destroy ] ],
      quote_line_items_attributes: [ [ :id, :item_type, :description, :quantity, :unit, :unit_price, :_destroy ] ]
    ])
  end
end
