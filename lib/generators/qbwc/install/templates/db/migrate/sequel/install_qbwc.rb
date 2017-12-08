Sequel.migration do
  change do
    create_table :qbwc_jobs do
      primary_key :id
      String :name
      String :company, fixed: true, size: 1000
      String :worker_class, fixed: true, size: 100
      FalseClass :enabled, null: false, default: false
      String :request_index
      String :requests
      FalseClass :requests_provided_when_job_added, null: false, default: false
      String :data
      DateTime :created_at
      DateTime :modified_at

      index :name, unique: true
      index :company
    end

    create_table :qbwc_sessions do
      primary_key :id
      String :ticket
      String :user
      String :company, size: 1000
      Integer :progress, null: false, default: 0
      String :current_job
      String :iterator_id
      String :error, size: 1000
      String :pending_jobs, null: false, size: 1000
      DateTime :created_at
      DateTime :modified_at
    end
  end
end
