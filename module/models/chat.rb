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

    def default_json
      doc = self.as_document
      doc["from_person"] = self.person
      doc.to_json( except: ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token", "person_id", "email_address_validated"])
    end

  end
end
