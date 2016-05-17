require_relative '../../spec_helper'

include Rack::Test::Methods

# Convenience methods
def convert_person_to_json person
	person.as_document.to_json
end

def expected_json_fields_for_person person
	JSON.parse(person.as_document.to_json( :except => ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token"] ))
end

def get_person_object_from_person_response person_response
	person_id = person_response["_id"]["$oid"]
	person = Gabb::Person.find(person_id)
end

def app
  Sinatra::Application
end

describe app do

	before do
		@person1 = create(:person, username: SecureRandom.hex)
		@person2 = create(:person, username: SecureRandom.hex)
		@person3 = create(:person, username: SecureRandom.hex)

    @admin_token = Gabb::AuthService.get_admin_token
    @app_token = Gabb::AuthService.get_app_token
    @person1_token = Gabb::AuthService.generate_token_for_person @person1
    @person2_token = Gabb::AuthService.generate_token_for_person @person2
	end

	describe 'app_root' do

    describe 'get /' do

      it 'must say hello world' do
        get '/'
        last_response.body.must_equal "Hello World!"
      end

    end

		describe 'GABB_BASE_URL' do
			it 'must have a value for Gabb BASE URL' do
				ENV['GABB_BASE_URL'].must_be_instance_of String
			end
		end

	end

  describe 'check options' do

    before do
      options "/"
    end

    it 'must indicate that any origin is allowed' do
      last_response.headers["Access-Control-Allow-Origin"].must_equal "*"
    end

    it 'must indicate that GET, POST and OPTIONS are allowed' do
      last_response.headers["Allow"].must_equal "GET,POST,OPTIONS"
    end

    it 'must indicate which headers are allowed' do
        last_response.headers["Access-Control-Allow-Headers"].must_equal "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization, Access-Control-Allow-Credentials"
    end

  end

  describe 'get /available' do

    describe 'look for a field that can be checked (username, email, phone)' do

      # describe 'unauthorized request' do
			#
      #   it 'must return a 401 status' do
      #     get "/available?username=user"
      #     last_response.status.must_equal 401
      #   end
      # end

      describe 'valid parameters' do

        before do
          get "/available?username=availableusername", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
        end

        it 'must return a 200 status code' do
          last_response.status.must_equal 200
        end

        it 'must return a JSON response indicating whether or not the field is valid' do
          result = JSON.parse(last_response.body)
          result.must_equal Hash["username", "available"]
        end

      end

      describe 'invalid parameters' do

        before do
          get "/available?name=Evan%20Waters", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
        end

        it 'must return a 404 status if the parameters cannot be checked' do
          last_response.status.must_equal 404
        end

        it 'must return an empty response body' do
          last_response.body.must_equal ""
        end

      end

    end

  end

	describe 'post /person/new' do

    describe 'create a person' do

  		before do
  			@username = SecureRandom.hex
  			data = '{"username": "' + @username + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "email": "' + Faker::Internet.email + '", "password": "password"}'
  			post "/person/new?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
  		end

  		it 'must return a 201 status code' do
  			last_response.status.must_equal 201
  		end

  		it 'must return an empty body' do
  			last_response.body.must_equal ""
  		end

  		it 'must include the person uri in the header' do
  			assert_match(/#{ENV['GABB_BASE_URL']}\/person\/id\/\w{24}/, last_response.header["location"])
  		end

    end

		describe 'duplicate username' do

			before do
				data = '{"username": "' + @person1.username + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "email": "' + Faker::Internet.email + '", "password": "password"}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "An account with that username already exists!"
			end

		end

		describe 'duplicate email' do

			before do
				data = '{"username": "' + SecureRandom.hex + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "email": "' + @person1.email + '", "password": "password"}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error if a duplicate email is posted' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "An account with that email already exists!"
			end

		end

		describe 'duplicate phone' do

			before do
				data = '{"username": "' + SecureRandom.hex + '", "phone": "' + @person1.phone + '", "email": "' + Faker::Internet.email + '", "password": "password"}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error if a duplicate phone is posted' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "An account with that phone number already exists!"
			end

		end

		describe 'no username' do

			before do
				data = '{"phone": "' + Faker::PhoneNumber.phone_number + '", "email": "' + Faker::Internet.email + '", "password": "password"}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error if no username is posted' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "Missing required field: username"
			end

		end

		describe 'no email' do

			before do
				data = '{"username": "' + SecureRandom.hex + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "password": "password"}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error if no email is posted' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "Missing required field: email"
			end

		end

		describe 'no password' do

			before do
				data = '{"username": "' + SecureRandom.hex + '", "email": "' + Faker::Internet.email + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "password": ""}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 403 error if no password is posted' do
				last_response.status.must_equal 403
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "Missing required field: password"
			end

		end

		## Commenting this out for now - will add auth requirements later.
		#
    # describe 'unauthorized request' do
		#
    #   it 'must return a 401 status if the request is not authorized' do
    #     username = SecureRandom.hex
    #     data = '{"username": "' + username + '", "phone": "' + Faker::PhoneNumber.phone_number + '", "email": "' + Faker::Internet.email + '", "password": "password"}'
    #     post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
    #     last_response.status.must_equal 401
    #   end
    # end

		describe 'malformed JSON' do

			before do
				username = SecureRandom.hex
        data = '{"username": "' + username + '" "phone": "' + Faker::PhoneNumber.phone_number + '}'
				post "/person/new", data, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
			end

			it 'must return a 400 status' do
				last_response.status.must_equal 400
			end

			it 'must return the correct error message' do
				response = JSON.parse(last_response.body)
				response["message"].must_equal "Malformed JSON"
			end

		end

	end

	describe '/person/id/:id' do

		describe 'get /person/id/:id' do

      describe 'record found' do

  			before do
  				get "/person/id/#{@person1.id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
  				@response = JSON.parse(last_response.body)
  			end

  			it 'must return a 200 status code' do
  				last_response.status.must_equal 200
  			end

  			it 'must return the expected fields' do
  				@response.must_equal expected_json_fields_for_person(@person1)
  			end

      end

      describe 'handle IF_MODIFIED_SINCE' do

        describe 'record has been modified since date specified' do

          before do
            if_modified_since = (@person1.updated_at - 5.days).to_s
            get "/person/id/#{@person1.id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}", "HTTP_IF_MODIFIED_SINCE" => if_modified_since}
            @response = JSON.parse(last_response.body)
          end

          it 'must have a 200 status code' do
            last_response.status.must_equal 200
          end

          it 'must return the person record if the IF_MODIFIED_SINCE date is earlier' do
            @response.must_equal expected_json_fields_for_person(@person1)
          end

        end

        describe 'record has not been modified since date specified' do

          before do
            if_modified_since = (@person1.updated_at).to_s
            get "/person/id/#{@person1.id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}", "HTTP_IF_MODIFIED_SINCE" => if_modified_since}
          end

          it 'must have a 304 status code' do
            last_response.status.must_equal 304
          end

          it 'must return an empty response body' do
            last_response.body.must_equal ""
          end

        end

      end

  		describe 'resource not found' do

  			before do
  				get "person/id/abc", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
  			end

  			it 'must return 404 if the person is not found' do
  				last_response.status.must_equal 404
  			end

  			it 'must return an empty response body if the person is not found' do
  				last_response.body.must_equal ""
  			end

  		end

      describe "unauthorized request" do

        it 'must return a 401 status if the request is not authorized' do
          get "/person/id/#{@person1.id}"
          last_response.status.must_equal 401
        end

      end

    end

		describe 'post /person/id/:id' do

			before do
				data = '{"city": "New York", "state": "NY"}'
				post "person/id/#{@person1.id}?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			end

			it 'must return a 204 status code' do
				last_response.status.must_equal 204
			end

			it 'must update the person record' do
				person = Gabb::Person.find(@person1.id)
				person.city.must_equal "New York"
			end

			it 'must not void fields that are not included in the update' do
				person = Gabb::Person.find(@person1.id)
				person.given_name.must_equal @person1.given_name
			end

		end

		describe 'prevent invalid updates' do

			it 'must return a 403 status if the username is attempted to be updated' do
				data = '{"username": "new_username"}'
				post "person/id/#{@person1.id}?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
				last_response.status.must_equal 403
			end

      describe 'duplicate an existing email address' do

        before do
          personA = create(:person, username: SecureRandom.hex, email: "#{SecureRandom.hex}@test.com")
          personB = create(:person, username: SecureRandom.hex, email: "#{SecureRandom.hex}@test.com")
          data = '{"email": "' + personA.email + '"}'
          post "person/id/#{personB.id}?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
        end

        it 'must return a 403 error if the update would duplicate an existing email address' do
          last_response.status.must_equal 403
        end

        it 'must return an error message in the response body' do
          message = JSON.parse(last_response.body)["message"]
          message.must_be_instance_of String
        end

      end

		end

    describe 'unauthorized request' do

      it 'must return a 401 status if a user tries to update another person record' do
        data = '{"city": "New York", "state": "NY"}'
        post "person/id/#{@person2.id}", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        last_response.status.must_equal 401
      end

    end

    describe 'authorize admin' do

      it 'must allow the admin to updtae a person record' do
        data = '{"city": "New York", "state": "NY"}'
        post "person/id/#{@person2.id}", data, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
        last_response.status.must_equal 204
      end

    end

	end

	describe '/login' do

		describe 'successful login' do

			before do
				# Creating a person with a password to test login
				person_attrs = attributes_for(:person)
				data = Hash["username", SecureRandom.hex, "name", person_attrs[:name], "email", Faker::Internet.email, "phone", Faker::PhoneNumber.phone_number, "password", "password"]
				@user = Gabb::PersonService.create_person data

				data = '{"username": "' + @user.username + '", "password": "password"}'
				post "/login", data
				@response = JSON.parse(last_response.body)
			end

			it 'must return a 200 status code' do
				last_response.status.must_equal 200
			end

      describe 'response body' do

        it 'must include the token in the response body' do
          @response["access_token"].must_be_instance_of String
        end

  			it 'must include the person record in the response body, including the id' do
  				BSON::ObjectId.from_string(@response["person"]["_id"]["$oid"]).must_equal @user.id
  			end

      end

			describe 'incorrect password' do

				it 'must return a 401 status code for an incorrect password' do
					data = '{"username": "' + @user.username + '", "password": "wrong_password"}'
					post "/login", data
					last_response.status.must_equal 401
				end

			end

		end

		describe 'unrecognized username' do

			before do
				data = '{"username": "unrecognized_username", "password": "wrong_password"}'
				post "/login", data
			end

			it 'must return a 401 status code for an unrecognized username' do
				last_response.status.must_equal 401
			end

		end

	end

	describe '/person/id/:id/reset_password' do

		before do
			person_attrs = attributes_for(:person)
			data = Hash["username", SecureRandom.hex, "name", person_attrs[:name], "email", Faker::Internet.email, "phone", Faker::PhoneNumber.phone_number, "password", "password"]
			@person = Gabb::PersonService.create_person data
		end

		describe 'submit the correct old password and a valid new password' do

			before do
				data = '{"old_password": "password", "new_password": "password123"}'
				post "/person/id/#{@person.id.to_s}/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
			end

			it 'must return a 204 status code' do
				last_response.status.must_equal 204
			end

			it 'must reset the password' do
				person_record = Gabb::Person.find(@person.id)
				person_record.hashed_password.must_equal Gabb::LoginService.hash_password "password123", person_record.salt
			end

			it 'must return an empty response body' do
				last_response.body.must_equal ""
			end

		end

		describe 'error conditions' do

			it 'must return a 404 error if the person record cannot be found' do
				data = '{"old_password": "password", "new_password": "password123"}'
				post "/person/id/abc123/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}

				last_response.status.must_equal 404
			end

			describe 'Runtime errors' do

				before do
					#Example case: Submit wrong password
					data = '{"old_password": "wrongpassword", "new_password": "password123"}'
					post "/person/id/#{@person.id.to_s}/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
				end

				it 'must return a 403 error' do
					last_response.status.must_equal 403
				end

				it 'must return a message indicating why the operation could not be completed' do
					response_body = JSON.parse(last_response.body)
					response_body["message"].must_equal "Existing password is incorrect"
				end

			end

		end

    describe 'unauthorized request' do
      it 'must return a 401 status if the request is not authorized' do
        data = '{"old_password": "password", "new_password": "password123"}'
        post "/person/id/#{@person.id.to_s}/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        last_response.status.must_equal 401
      end
    end

	end

  describe '/validate_email' do

    before do
      @token = Gabb::AuthService.get_email_validation_token @person1
      post "/validate_email", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"}
    end

    it 'must return an Access-Control-Allow-Origin header' do
      last_response.headers["Access-Control-Allow-Origin"].must_equal "*"
    end

    it 'must return a 204 status' do
      last_response.status.must_equal 204
    end

    it 'must mark the email address as valid' do
      person = Gabb::Person.find(@person1.id)
      person.email_address_validated.must_equal true
    end

    it 'must flag the token as invalid so that it cannot be used again' do
      db_token = Gabb::Token.find_by(value: @token)
      db_token.is_invalid.must_equal true
    end

    describe 'error conditions' do

      it 'must return a 401 status if the token has expired' do
        payload = Gabb::AuthService.generate_payload_for_email_validation @person1
        payload[:exp] = Time.now.to_i - 60
        token = Gabb::AuthService.generate_token payload
        post "/validate_email", nil, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}

        last_response.status.must_equal 401
      end

      it 'must return a 401 status if the token does not have the validate-email scope' do
        post "/validate_email", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        last_response.status.must_equal 401
      end

      it 'must return a 401 status if the same token is used twice' do
        token = Gabb::AuthService.get_email_validation_token @person1
        post "/validate_email", nil, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
        post "/validate_email", nil, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
        last_response.status.must_equal 401
      end

    end

  end

  describe '/reset_password' do

    before do
      @token = Gabb::AuthService.get_password_reset_token @person1
      data = '{"password": "password123"}'
      post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"}
    end

    it 'must return an Access-Control-Allow-Origin header' do
      last_response.headers["Access-Control-Allow-Origin"].must_equal "*"
    end

    it 'must return a 204 status' do
      last_response.status.must_equal 204
    end

    it 'must reset the password' do
      new_person_record = Gabb::Person.find(@person1.id)
      new_person_record.hashed_password.must_equal Gabb::LoginService.hash_password "password123", new_person_record.salt
    end

    it 'must flag the token as invalid so that it cannot be used again' do
      db_token = Gabb::Token.find_by(value: @token)
      db_token.is_invalid.must_equal true
    end

    describe 'error conditions' do

      it 'must return a 401 status if the token has expired' do
        payload = Gabb::AuthService.generate_payload_for_password_reset @person1
        payload[:exp] = Time.now.to_i - 60
        token = Gabb::AuthService.generate_token payload
        data = '{"password": "password123"}'
        post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}

        last_response.status.must_equal 401
      end

      it 'must return a 401 status if the token does not have the reset-password scope' do
        data = '{"password": "password123"}'
        post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        last_response.status.must_equal 401
      end

      it 'must return a 401 status if the same token is used twice' do
        token = Gabb::AuthService.get_password_reset_token @person1
        data = '{"password": "password123"}'
        post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
        post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
        last_response.status.must_equal 401
      end

      it 'must return a 403 status if the data does not include a "password" field' do
        token = Gabb::AuthService.get_password_reset_token @person2
        data = '{"wrong": "password123"}'
        post "/reset_password", data, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
        last_response.status.must_equal 403
      end

    end

  end

  describe 'request password reset token' do

		describe 'email enabled' do

			before do
				ENV['GABB_EMAIL_ENABLED'] = 'yes'
        ENV['GABB_POSTMARK_EMAIL_ADDRESS'] = "test@test.com"
			end

			describe 'successful request' do

	      before do
	        data = '{"email": "' + @person1.email + '"}'
	        post "/request_password_reset?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
	      end

	      it 'must return a 201 status' do
	        last_response.status.must_equal 201
	      end

	      it 'must return an empty response' do
	        last_response.body.must_equal ""
	      end

	    end

	    describe 'email does not match an account' do

	      before do
	        data = '{"email": "notanemail@notaprovider.com"}'
	        post "/request_password_reset", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
	      end

	      it 'must return a 404 status' do
	        last_response.status.must_equal 404
	      end

	      it 'must return an error message' do
	        response = JSON.parse(last_response.body)
	        response["message"].must_equal "An account with that email does not exist."
	      end

	    end

			describe 'email disabled' do

				before do
					ENV['GABB_EMAIL_ENABLED'] = 'no'
					data = '{"email": "' + @person1.email + '"}'
					post "/request_password_reset?test=true", data, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
				end

				it 'must return a 403 status' do
					last_response.status.must_equal 403
				end

			end

		end

  end

	describe '/people' do

    describe 'get all people' do

      before do
      	get '/people', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      end

  		it 'must return a 200 status code' do
  			last_response.status.must_equal 200
  		end

  		it 'must return a collection with all of the people if no parameters are entered' do
  			collection = JSON.parse(last_response.body)
  			num_people = Gabb::Person.count
  			collection.length.must_equal num_people
  		end

  		it 'must return a filtered collection if parameters are given' do
  			get "/people?name=Evan", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
  			expected_number = Gabb::Person.where(name: "Evan").count
  			actual_number = JSON.parse(last_response.body).count
  			actual_number.must_equal expected_number
  		end

  		it 'must return the expected information for a person record' do
  			get "/people?id=#{@person1.id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
  			people_response = JSON.parse(last_response.body)

  			people_response[0].must_equal expected_json_fields_for_person(@person1)
  		end

    end

    describe 'get only records that were created or updated after a specific date and time' do

      before do
        @person4 = create(:person, username: SecureRandom.hex)
        person_record = Gabb::Person.find(@person3.id)
        @timestamp = person_record.updated_at
        @timestamp_string = JSON.parse(person_record.as_document.to_json)["updated_at"]
        get "/people", nil, {"HTTP_IF_MODIFIED_SINCE" => @timestamp_string, "HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      end

      it 'must include the timestamp in the header' do
        last_request.env["HTTP_IF_MODIFIED_SINCE"].must_equal @timestamp
      end

      it 'must only return people records that were created or updated after the timestamp' do
        num_returned = JSON.parse(last_response.body).count
        expected_number = Gabb::Person.where({updated_at: { "$gt" => @timestamp } }).count
        num_returned.must_equal expected_number
      end

    end

    describe 'unauthorized request' do
      it 'must return a 401 status if the request is not authorized' do
        get "/people", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
        last_response.status.must_equal 401
      end
    end

	end

	describe '/people/search' do

		before do

			@rando_name = SecureRandom.hex

			@person5 = create(:person, given_name: @rando_name, username: SecureRandom.hex)
			@person6 = create(:person, given_name: @rando_name, username: SecureRandom.hex)
			@person7 = create(:person, given_name: @rando_name, username: SecureRandom.hex)

			get "/people/search?term=#{@rando_name}&limit=2", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			@response = JSON.parse(last_response.body)

		end

		it 'must return a 200 status code' do
			last_response.status.must_equal 200
		end

		it 'must limit the number of records returned based on the limit parameter' do
			assert_operator @response.count, :<=, 2
		end

		it 'must return the expected information for a person record' do
			first_result = get_person_object_from_person_response @response[0]
			@response[0].must_equal expected_json_fields_for_person(first_result)
		end

	end

  describe '/people/find_matches' do
    before do
      @personA = create(:person, username: SecureRandom.hex, email: "person1@google.com")
			@personB = create(:person, username: SecureRandom.hex, email: "person2@google.com")
			@personC = create(:person, username: SecureRandom.hex, email: "person3@google.com")
			@personD = create(:person, username: SecureRandom.hex, email: "person4@google.com")

      data = '{"emails": ["person1@google.com", "person2@google.com", "person@yahoo.com", "person@hotmail.com", "person4@google.com"]}'

			post "/people/find_matches", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}

      @parsed_response = JSON.parse(last_response.body)
    end

    it 'must return a 201 status code if matches are found' do
      last_response.status.must_equal 201
    end

    it 'must return a JSON document with the relevant people records for people with matching emails' do
      @parsed_response.to_s.include?("person1@google.com").must_equal true
    end

    it 'must return all of the matching records' do
      @parsed_response.count.must_equal 3
    end

    it 'must return the expected fields for a person' do
      first_result = get_person_object_from_person_response @parsed_response[0]
      @parsed_response[0].must_equal expected_json_fields_for_person(first_result)
    end

  end

  describe '/upload' do

    describe 'upload a file' do

      before do
        image_file = File.open('spec/resources/image1.jpg')
        @filename = 'image1.jpg'
        @image_file_size = File.size(image_file)
        base64_string = Base64.encode64(image_file.read)
        data = '{"file": "' + base64_string + '", "filename": "image1.jpg"}'
        post "/upload", data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        image_file.close
      end

      it 'must return a 201 status code if a file is successfuly uploaded' do
        last_response.status.must_equal 201
      end

      it 'must return an empty response body' do
        last_response.body.must_equal ""
      end

      it 'must include the uid in the header' do
        last_response.headers["location"].must_be_instance_of String
      end

      it 'must upload the object to the AWS S3 store' do
        uid = last_response.headers["location"]
        Dragonfly.app.fetch(uid).name.must_equal @filename
      end

      it 'must upload the complete contents of the file as the AWS object' do
        uid = last_response.headers["location"]
        Dragonfly.app.fetch(uid).size.must_equal @image_file_size
      end

    end

  end

  describe 'get image by its uid' do

    describe 'get an image' do

      before do
        get "/image/resources/cards/Dhow.jpg", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      end

      it 'must redirect and return a 302 status' do
        last_response.status.must_equal 302
      end

    end

    describe 'get an image that is not in the resources directory' do

      before do
        image = File.open('spec/resources/image2.jpg')
        @uid = Dragonfly.app.store(image.read, 'name' => 'image2.jpg')
      end

      it 'must succeed if the token has can-read scope' do
        get "/image/#{@uid}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
        last_response.status.must_equal 302
      end

    end

  end

	describe 'get podcasts/listening' do

		before do

	    @podcast1 = Hash("podcast_id" => 1, "title" => "Awesome podcast", "image_url" => "http://example.com/image.jpg", "feed_url" => "http://example.com/podcast/feed")
	    @podcast2 = Hash("podcast_id" => 2, "title" => "Awesome podcast", "image_url" => "http://example.com/image.jpg", "feed_url" => "http://example.com/podcast/feed")

	    @session1 = @person1.sessions.create!(Hash(episode_hash: "foobar", podcast: @podcast1))

	    sleep(0.1)
	    @session2 = @person1.sessions.create!(Hash(episode_hash: "foobar", podcast: @podcast1))

	    sleep(0.1)
	    @session3 = @person1.sessions.create!(Hash(episode_hash: "barfoo", podcast: @podcast1))

	    sleep(0.1)
	    @session4 = @person1.sessions.create!(Hash(episode_hash: "fortran", podcast: @podcast2))
	  end

		it 'must return the podcasts the person has been listening to' do
			get '/podcasts/listening', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 200
			podcasts = JSON.parse(last_response.body)["podcasts"]
			podcasts.count.must_equal 2
			podcasts[0].must_equal @podcast2
			podcasts[1].must_equal @podcast1
		end

	end

	describe 'post sessions/start' do

		before do
			@hash = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => rand(1000000000))
			@data = JSON.generate(@hash)
		end

		it 'must start the session' do
			post '/session/start', @data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 201
			assert_match(/#{ENV['GABB_BASE_URL']}\/session\/id\/\w{24}/, last_response.header["location"])
			last_response.body.must_equal ""
			@person1.sessions.last.start_time_value.must_equal @hash["time_value"]
		end

	end

	describe 'post sessions/stop' do

		before do
			@hash = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => rand(1000000000))
			@data = JSON.generate(@hash)
		end

		it 'must stop the session' do
			post '/session/stop', @data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 204
			assert_match(/#{ENV['GABB_BASE_URL']}\/session\/id\/\w{24}/, last_response.header["location"])
			last_response.body.must_equal ""
			@person1.sessions.last.stop_time_value.must_equal @hash["time_value"]
		end

	end

	describe 'post sessions/finish' do

		before do
			@hash = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => rand(1000000000))
			@data = JSON.generate(@hash)
		end

		it 'must finish the session' do
			post '/session/finish', @data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 204
			assert_match(/#{ENV['GABB_BASE_URL']}\/session\/id\/\w{24}/, last_response.header["location"])
			last_response.body.must_equal ""
			@person1.sessions.last.stop_time_value.must_equal @hash["time_value"]
			@person1.sessions.last.finished.must_equal true
		end

	end

	describe 'get /session/last' do

		before do
			@session1 = @person1.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session2 = @person1.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session3 = @person1.sessions.create!(Hash(episode_hash: "barfoo"))
		end

		it 'must get the last session, passing in parameters if available' do

			get '/session/last', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 200
			session = JSON.parse(last_response.body)
			session["episode_hash"].must_equal "barfoo"

			get '/session/last?episode_hash=foobar', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			session = JSON.parse(last_response.body)
			session["episode_hash"].must_equal "foobar"
		end

	end

	describe 'get /sessions' do

		before do
      @session1 = @person1.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session2 = @person1.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session3 = @person1.sessions.create!(Hash(episode_hash: "barfoo"))
      sleep(0.1)
      @session4 = @person1.sessions.create!(Hash(episode_hash: "fortran"))
    end

		it 'must return the last session for each episode hash' do
			get '/sessions', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 200
			sessions = JSON.parse(last_response.body)
			sessions.count.must_equal 3
			(sessions.select { |a| a["episode_hash"] == "foobar" }).count.must_equal 1
			(sessions.select { |a| a["episode_hash"] == "barfoo" }).count.must_equal 1
			(sessions.select { |a| a["episode_hash"] == "fortran" }).count.must_equal 1
		end

	end

	describe 'get /chats' do

		before do
			3.times do
        @person1.chats.create!(Hash(podcast_id: 2))
      end

      2.times do
        @person1.chats.create!(Hash(podcast_id: 3))
      end

      2.times do
        @person2.chats.create!(Hash(podcast_id: 2))
      end
		end

		it 'must return chats, passing in filter parameters if they are given' do
			get '/chats', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 200
			chats = JSON.parse(last_response.body)
			chats.count.must_equal Gabb::Chat.count

			get '/chats?podcast_id=2', nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			chats = JSON.parse(last_response.body)
			chats.count.must_equal Gabb::Chat.where(podcast_id: 2).count
		end

	end

	describe 'post /chat' do

		before do
			@hash = Hash("podcast_id" => 2, "text" => "Whoop dee doo")
			@data = JSON.generate(@hash)
		end

		it 'must stop the session' do
			post '/chat', @data, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 201
			assert_match(/#{ENV['GABB_BASE_URL']}\/chat\/id\/\w{24}/, last_response.header["location"])
			last_response.body.must_equal ""
			@person1.chats.last.text.must_equal @hash["text"]
		end

	end

	describe 'get /chat/id/:id' do

		before do
			@chat = @person1.chats.create!(Hash(podcast_id: 2))
		end

		it 'must get the chat' do
			get "/chat/id/#{@chat.id.to_s}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
			last_response.status.must_equal 200

			response = JSON.parse(last_response.body)
			response["_id"]["$oid"].must_equal @chat.id.to_s

		end

	end

end
