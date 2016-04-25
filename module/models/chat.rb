module Gabb
  class Chat

    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :person

    field :text, type: String
    field :podcast_id, type: Integer

    index({ podcast_id: 1})

    def uri
			"#{ENV['GABB_BASE_URL']}/chat/id/#{self.id}"
		end

    def as_json
      self.as_document.to_json
    end

  end
end
