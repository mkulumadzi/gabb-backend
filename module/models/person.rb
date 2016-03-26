module Gabb
	class Person
		include Mongoid::Document
		include Mongoid::Timestamps

		field :username, type: String
		field :given_name, type: String
		field :family_name, type: String
		field :email, type: String
		field :email_address_validated, type: Boolean
		field :phone, type: String
		field :hashed_password, type: String
		field :salt, type: String
		field :address1, type: String
		field :city, type: String
		field :state, type: String
		field :zip, type: String
		field :device_token, type: String
		field :facebook_id, type: String
		field :facebook_token, type: String

		index({ username: 1 }, { unique: true })
		index({ email: 1 })
		index({ phone: 1 })
		index({ facebook_id: 1 })

		def initials
			if given_name && family_name && given_name.length > 0 && family_name.length > 0
				given_name[0] + family_name[0]
			elsif given_name && given_name.length > 0
				given_name[0..1]
			elsif family_name && family_name.length > 0
				family_name[0..1]
			else
				""
			end
		end

		def full_name
			if given_name && family_name
				given_name + " " + family_name
			elsif given_name
				given_name
			else
				family_name
			end
		end

		def mark_email_as_valid
			self.email_address_validated = true
			self.save
		end

		def uri
			"#{ENV['GABB_BASE_URL']}/person/id/#{self.id}"
		end

		def as_json
			self.as_document.to_json( :except => ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token"] )
		end

	end
end
