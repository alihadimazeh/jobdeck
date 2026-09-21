class ActivityNotesController < ApplicationController
  before_action :set_notable,      only: %i[ create ]
  before_action :set_activity_note, only: %i[ edit update destroy ]

  # POST /leads/:lead_id/activity_notes
  # POST /jobs/:job_id/activity_notes
  # POST /jobs/:job_id/orders/:order_id/activity_notes
  def create
    @activity_note = @notable.activity_notes.build(activity_note_params)

    respond_to do |format|
      if @activity_note.save
        format.html { redirect_to @activity_note.notable, notice: "Note added." }
        format.json { render :show, status: :created, location: @activity_note }
      else
        format.html { redirect_to @notable, alert: @activity_note.errors.full_messages.to_sentence }
        format.json { render json: @activity_note.errors, status: :unprocessable_content }
      end
    end
  end

  # GET /activity_notes/1/edit
  def edit
  end

  # PATCH/PUT /activity_notes/1
  def update
    respond_to do |format|
      if @activity_note.update(activity_note_params)
        format.html { redirect_to @activity_note.notable, notice: "Note was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @activity_note }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @activity_note.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /activity_notes/1
  def destroy
    notable = @activity_note.notable

    if @activity_note.destroy
      respond_to do |format|
        format.html { redirect_to notable, notice: "Note was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      redirect_to notable, alert: "Could not delete note.", status: :see_other
    end
  end

  private

  def set_notable
    @notable = if params[:lead_id]
                 Lead.find(params[:lead_id])
    elsif params[:order_id]
                 Order.find(params[:order_id])
    elsif params[:job_id]
                 Job.find(params[:job_id])
    end
  end

  def set_activity_note
    @activity_note = ActivityNote.find(params.expect(:id))
  end

  def activity_note_params
    params.expect(activity_note: [ :body, :author, :pinned ])
  end
end
