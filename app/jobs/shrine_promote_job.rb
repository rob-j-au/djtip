class ShrinePromoteJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(record_class, record_id, name, file_data)
    record = record_class.constantize.find(record_id)
    attacher = record.send("#{name}_attacher")
    
    attacher.class.promote(file_data)
  end
end
