module Gabb
  class Session

    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :person

    field :episode_url, type: String
    field :episode_hash, type: String
    field :start_time_scale, type: Integer
    field :start_time_value, type: Integer
    field :stop_time_scale, type: Integer
    field :stop_time_value, type: Integer

    index({ episode_hash: 1})

    def uri
			"#{ENV['GABB_BASE_URL']}/session/id/#{self.id}"
		end

		def as_json
			self.as_document.to_json( :except => ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token"] )
		end

  end
end
