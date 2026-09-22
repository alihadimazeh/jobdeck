# Re-renders the polymorphic parent's (Lead/Job/Order) show page with a 422, so a failed
# nested create keeps the user's input and shows field-level errors instead of redirecting.
module RendersParentShow
  private

  def render_parent_show(parent)
    instance_variable_set("@#{parent.model_name.element}", parent)
    render "#{parent.model_name.route_key}/show", status: :unprocessable_content
  end
end
