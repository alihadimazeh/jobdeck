require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lead = leads(:one)
  end

  test "should get index" do
    get leads_url
    assert_response :success
  end

  test "should get new" do
    get new_lead_url
    assert_response :success
  end

  test "should create lead" do
    assert_difference("Lead.count") do
      post leads_url, params: { lead: { assigned_to: @lead.assigned_to, customer_id: @lead.customer_id, description: @lead.description, estimated_value: @lead.estimated_value, job_type: @lead.job_type, source: @lead.source, status: @lead.status, title: @lead.title } }
    end

    assert_redirected_to lead_url(Lead.last)
  end

  test "should show lead" do
    get lead_url(@lead)
    assert_response :success
  end

  test "should get edit" do
    get edit_lead_url(@lead)
    assert_response :success
  end

  test "should update lead" do
    patch lead_url(@lead), params: { lead: { assigned_to: @lead.assigned_to, customer_id: @lead.customer_id, description: @lead.description, estimated_value: @lead.estimated_value, job_type: @lead.job_type, source: @lead.source, status: @lead.status, title: @lead.title } }
    assert_redirected_to lead_url(@lead)
  end

  test "should destroy lead" do
    assert_difference("Lead.count", -1) do
      delete lead_url(@lead)
    end

    assert_redirected_to leads_url
  end
end
