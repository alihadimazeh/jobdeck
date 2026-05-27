json.extract! job, :id, :title, :status, :job_type, :source, :estimated_value, :assigned_to, :description, :customer_id, :lead_id, :created_at, :updated_at
json.url job_url(job, format: :json)
