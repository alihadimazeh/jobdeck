class DocumentsController < ApplicationController
  before_action :set_documentable, only: %i[ create ]
  before_action :set_document,     only: %i[ destroy ]

  # POST /leads/:lead_id/documents
  # POST /jobs/:job_id/documents
  # POST /jobs/:job_id/orders/:order_id/documents
  def create
    @document = @documentable.documents.build(document_params)

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document.documentable, notice: "Document added." }
        format.json { render :show, status: :created, location: @document }
      else
        format.html { redirect_to @documentable, alert: @document.errors.full_messages.to_sentence }
        format.json { render json: @document.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /documents/1
  def destroy
    documentable = @document.documentable

    if @document.destroy
      respond_to do |format|
        format.html { redirect_to documentable, notice: "Document was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to documentable, alert: "Could not delete document.", status: :see_other
    end
  end

  private

  def set_documentable
    @documentable = if params[:lead_id]
                       Lead.find(params[:lead_id])
    elsif params[:order_id]
                       Order.find(params[:order_id])
    elsif params[:job_id]
                       Job.find(params[:job_id])
    end
  end

  def set_document
    @document = Document.find(params.expect(:id))
  end

  def document_params
    params.expect(document: [ :label, :document_type, :description, :uploaded_by, :file ])
  end
end
