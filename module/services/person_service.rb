module SkeletonApp

	class PersonService

		def self.create_person data

			salt = nil
			hashed_password = nil

			if data["password"]
				salt = SkeletonApp::LoginService.salt
				hashed_password = SkeletonApp::LoginService.hash_password data["password"], salt
			end

			if data["phone"]
				phone = self.format_phone_number data["phone"]
			end

			self.validate_required_fields data

			email_validated = nil
			if data["facebook_id"] != nil && data["facebook_id"] != ""
				email_validated = true
			else
				email_validated = false
			end

			SkeletonApp::Person.create!({
		      username: data["username"],
					given_name: data["given_name"],
					family_name: data["family_name"],
		      email: data["email"],
					email_address_validated: email_validated,
		      phone: phone,
		      address1: data["address1"],
		      city: data["city"],
		      state: data["state"],
		      zip: data["zip"],
		      salt: salt,
		      hashed_password: hashed_password,
		      device_token: data["device_token"],
					facebook_id: data["facebook_id"],
					facebook_token: data["facebook_token"]
		    })
		end

		def self.validate_required_fields data
			if data["username"] == nil || data["username"] == ""
				raise "Missing required field: username"
			elsif data["email"] == nil || data["email"] == ""
				raise "Missing required field: email"
			elsif SkeletonApp::Person.where(email: data["email"]).exists?
				raise "An account with that email already exists!"
			elsif SkeletonApp::Person.where(phone: data["phone"]).exists? && data["phone"] != "" && data["phone"] != nil
				raise "An account with that phone number already exists!"
			elsif data["password"] == nil || data["password"] == ""
				raise "Missing required field: password"
			end
		end

		def self.format_phone_number phone
			phone.tr('^0-9', '')
		end

		def self.update_person person, data
			data["username"] ? raise(ArgumentError) : nil

			if data["email"] && data["email"] != person.email && SkeletonApp::Person.where(email: data["email"]).exists?
				raise "An account with that email already exists!"
			end

			person.update_attributes!(data)
		end

		def self.get_people params = {}
			people = []
			SkeletonApp::Person.where(params).each do |person|
				people << person.as_document
			end
			people
		end

		def self.search_people params
			people = []
			query = self.create_query_for_search_term params["term"]

			if params["limit"]
				search_limit = params["limit"]
			else
				search_limit = 25
			end

			query.limit(search_limit).each { |person| people << person }
			people
		end

		def self.create_query_for_search_term term
			search_terms = term.split('+')
			if search_terms.length == 1
				SkeletonApp::Person.or({given_name: /#{term}/}, {family_name: /#{term}/}, {username: /#{term}/})
			else
				first_term = search_terms[0]
				second_term = search_terms[1]
				SkeletonApp::Person.or({given_name: /#{first_term}/, family_name: /#{second_term}/},{given_name: /#{second_term}/, family_name: /#{first_term}/})
			end
		end

		def self.find_people_from_list_of_emails email_array
			people = []
			email_array.each do |email|
				if SkeletonApp::Person.where(email: email).count > 0
					people << SkeletonApp::Person.where(email: email).first
				end
			end
			people
		end

		def self.check_field_availability params
			fields_that_can_be_checked = ["username", "phone", "email"]
			if params.count > 1
				raise "Only one field may be checked at a time"
			elsif fields_that_can_be_checked.index(params.keys[0]) == nil
				raise "#{params.keys[0]} cannot be checked"
			else
				begin
					SkeletonApp::Person.find_by(params)
					return Hash[params.keys[0], "unavailable"]
				rescue Mongoid::Errors::DocumentNotFound
					return Hash[params.keys[0], "available"]
				end
			end

		end

	end

end
