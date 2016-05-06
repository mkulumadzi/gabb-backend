module Gabb
  class Session

    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Attributes::Dynamic

    belongs_to :person

    field :podcast, type: Hash, default: Hash.new
    field :title, type: String
    field :episode_url, type: String
    field :episode_hash, type: String
    field :start_time_scale, type: Integer
    field :start_time_value, type: Integer
    field :stop_time_scale, type: Integer
    field :stop_time_value, type: Integer

    index({ episode_hash: 1})
    index({ podcast_info: 1})

    def uri
			"#{ENV['GABB_BASE_URL']}/session/id/#{self.id}"
		end

		def as_json
			self.as_document.to_json
		end

  end
end
