class QuotesController < ApplicationController
  before_action :set_lead,  only: %i[ index new create ]
  before_action :set_quote, only: %i[ show edit update destroy ]

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

    if @quote.save
      redirect_to @quote, notice: "Quote was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /quotes/:id
  def update
    if @quote.update(quote_params)
      redirect_to @quote, notice: "Quote was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /quotes/:id
  def destroy
    @lead = @quote.lead
    @quote.destroy
    redirect_to lead_quotes_path(@lead), notice: "Quote was successfully deleted.", status: :see_other
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
