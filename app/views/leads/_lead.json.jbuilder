json.extract! lead, :id, :title, :status, :job_type, :source, :estimated_value, :assigned_to, :description, :customer_id, :job_id, :created_at, :updated_at
json.url lead_url(lead, format: :json)
