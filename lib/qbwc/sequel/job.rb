class QBWC::Sequel::Job < QBWC::Job
  class QbwcJob < Sequel::Model
    plugin :serialization
    plugin :timestamps, update_on_create: true

    serialize_attributes :yaml, :requests, :request_index, :data

    #validates :name, :uniqueness => true, :presence => true

    def to_qbwc_job
      QBWC::Sequel::Job.new(name, enabled, company, worker_class, requests, data)
    end

  end

  # Creates and persists a job.
  def self.add_job(name, enabled, company, worker_class, requests, data)
    worker_class = worker_class.to_s
    sequel_job = find_sequel_job_with_name(name).first || QbwcJob.new(name: name)
    sequel_job.company = company
    sequel_job.enabled = enabled
    sequel_job.worker_class = worker_class
    sequel_job.save(raise_on_failure: true)

    jb = self.new(name, enabled, company, worker_class, requests, data)
    unless requests.nil? || requests.empty?
      request_hash = { [nil, company] => [requests].flatten }

      jb.requests = request_hash
      sequel_job.update requests: request_hash
    end
    jb.requests_provided_when_job_added = (!requests.nil? && !requests.empty?)
    jb.data = data
    jb
  end

  def self.find_job_with_name(name)
    j = find_sequel_job_with_name(name).first
    j = j.to_qbwc_job unless j.nil?
    return j
  end

  def self.find_sequel_job_with_name(name)
    QbwcJob.where(name: name.to_s)
  end

  def find_sequel_job
    self.class.find_sequel_job_with_name(name)
  end

  def self.delete_job_with_name(name)
    j = find_sequel_job_with_name(name).first
    j.destroy unless j.nil?
  end

  def enabled=(value)
    update_job(enabled: true)
  end

  def enabled?
    find_sequel_job.where(enabled: true).count > 0
  end

  def requests(session = QBWC::Session.get)
    @requests = pluck_from_job(:requests)
    super
  end

  def set_requests(session, requests)
    super
    update_job(requests: @requests)
  end

  def requests_provided_when_job_added
    pluck_from_job(:requests_provided_when_job_added)
  end

  def requests_provided_when_job_added=(value)
    update_job(requests_provided_when_job_added: value)
    super
  end

  def data
    pluck_from_job(:data)
  end

  def data=(r)
    update_job(data: r)
    super
  end

  def request_index(session)
    (pluck_from_job(:request_index) || {})[session.key] || 0
  end

  def set_request_index(session, index)
   find_sequel_job.each do |jb|
      jb.request_index[session.key] = index
      jb.save
    end
  end

  def advance_next_request(session)
    nr = request_index(session)
    set_request_index session, nr + 1
  end

  def reset
    super
    update_job(request_index: {})
    update_job(requests: {}) unless requests_provided_when_job_added
  end

  def update_job(hash)
    find_sequel_job.each { |x| x.update(hash) }
  end

  def pluck_from_job(sym)
    find_sequel_job.map { |x| x.send(sym) }.first
  end

  def self.list_jobs
    QbwcJob.map { |sequel_job| sequel_job.to_qbwc_job }
  end

  def self.clear_jobs
    QbwcJob.dataset.delete
  end

  def self.sort_in_time_order(ary)
    ary.sort {|a,b| a.find_sequel_job.first.created_at <=> b.find_sequel_job.first.created_at}
  end

end
