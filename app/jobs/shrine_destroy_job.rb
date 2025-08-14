class ShrineDestroyJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(attacher_data)
    attacher = Shrine::Attacher.from_data(attacher_data)
    attacher.destroy
  end
end
