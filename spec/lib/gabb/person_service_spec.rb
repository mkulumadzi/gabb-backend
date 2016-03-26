require_relative '../../spec_helper'

describe Gabb::PersonService do

	describe 'create person' do

		before do
			#Setting up random values, since these need to be unique
			@username = SecureRandom.hex
			@phone = rand(1000000000).to_s
			@email = SecureRandom.uuid()

			data = Hash["given_name", "Evan", "family_name", "Waters", "username", @username, "email", @email, "phone", @phone, "address1", "test", "city", "test", "state", "CA", "zip", "55555", "password", "password", "facebook_id", "123", "facebook_token", "abcdef"]
			@person = Gabb::PersonService.create_person data
		end

		it 'must create a new person record' do
			@person.must_be_instance_of Gabb::Person
		end

		it 'must store the username' do
			@person.username.must_equal @username
		end

		it 'must store the given name' do
			@person.given_name.must_equal 'Evan'
		end

		it 'must store the family name' do
			@person.family_name.must_equal 'Waters'
		end

		describe 'validate required fields' do

			it 'must throw an exception if username is missing' do
				data = Hash["email", "testemail", "phone", "685714571", "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must throw an exception is username is empty' do
				data = Hash["username", "", "email", "testemail", "phone", "685714571", "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must throw an exception if email is missing' do
				data = Hash["username", "test", "phone", "685714571", "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must throw an exception is email is empty' do
				data = Hash["username", "test", "email", "", "phone", "685714571", "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must throw an exception if email is duplicate' do
				data = Hash["username", "test", "email", @person.email, "phone", "685714571", "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must throw an exception if phone is duplicate' do
				data = Hash["username", "test", "email", "wha@test.co", "phone", @person.phone, "password", "password"]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must not throw an exception if phone is empty' do
				data = Hash["username", "test", "email", "wha@test.co", "phone", "", "password", "password"]
				Gabb::PersonService.validate_required_fields(data).must_equal nil
			end

			it 'must not thrown an exception if no phone is submitted' do
				data = Hash["username", "test", "email", "wha@test.co", "password", "password"]
				Gabb::PersonService.validate_required_fields(data).must_equal nil
			end

			it 'must throw an exception is password is empty' do
				data = Hash["username", "test", "email", "test", "phone", "5556665555", "password", ""]
				assert_raises RuntimeError do
					Gabb::PersonService.validate_required_fields data
				end
			end

			it 'must call this function when creating a person' do
				username = SecureRandom.hex
				phone = rand(1000000)
				data = Hash["username", username, "email", "#{@person.email}", "phone", phone.to_s, "password", "password"]

				assert_raises RuntimeError do
					Gabb::PersonService.create_person data
				end
			end

		end

		it 'must store the email' do
			@person.email.must_equal @email
		end

		describe 'email validation' do

			it 'must indicate that the email address has been validated if the data includes a facebook_id' do
				@person.email_address_validated.must_equal true
			end

			it 'must indicate the email has not been validated if the data does not include a facebook_id' do
				username = SecureRandom.hex
				email = SecureRandom.hex + "@test.com"
				data = Hash["given_name", "Evan", "family_name", "Waters", "username", username, "email", email, "address1", "121 W 3rd St", "city", "New York", "state", "NY", "zip", "10012", "password", "password"]
				person = Gabb::PersonService.create_person data
				person.email_address_validated.must_equal false
			end

			it 'must indicate the email has not been validated if the data includes an empty facebook_id' do
				username = SecureRandom.hex
				email = SecureRandom.hex + "@test.com"
				data = Hash["given_name", "Evan", "family_name", "Waters", "username", username, "email", email, "address1", "121 W 3rd St", "city", "New York", "state", "NY", "zip", "10012", "password", "password", "facebook_id", ""]
				person = Gabb::PersonService.create_person data
				person.email_address_validated.must_equal false
			end

		end

		describe 'store the phone number' do

			it 'must remove spaces from the phone number' do
				phone = Gabb::PersonService.format_phone_number '555 444 3333'
				phone.must_equal '5554443333'
			end

			it 'must remove special characters from the phone number' do
				phone = Gabb::PersonService.format_phone_number '(555)444-3333'
				phone.must_equal '5554443333'
			end

			it 'must remove letters from the phone number' do
				phone = Gabb::PersonService.format_phone_number 'aB5554443333'
				phone.must_equal '5554443333'
			end

			it 'must store the phone number as a string of numeric digits' do
				@person.phone.must_equal Gabb::PersonService.format_phone_number @phone
			end

		end

		it 'must store the address' do
			@person.address1.must_equal 'test'
		end

		it 'must store the city' do
			@person.city.must_equal 'test'
		end

		it 'must store the state' do
			@person.state.must_equal 'CA'
		end

		it 'must store the zip code' do
			@person.zip.must_equal '55555'
		end

		it 'must store the salt as a String' do
			@person.salt.must_be_instance_of String
		end

		it 'must store the hashed password as a String' do
			@person.hashed_password.must_be_instance_of String
		end

		it 'must store the facebook id' do
			@person.facebook_id.must_equal "123"
		end

		it 'must store the facebook token' do
			@person.facebook_token.must_equal "abcdef"
		end

	end

	describe 'update person' do

		before do
			@person = create(:person, username: SecureRandom.hex)
		end

		describe 'successful update' do

			before do
				data = Hash("given_name" => "New", "family_name" => "Name", "email" => "#{SecureRandom.hex}@test.com")
				Gabb::PersonService.update_person @person, data
				@updated_record = Gabb::Person.find(@person.id)
			end

			it 'must have updated the attributes that were provided' do
				@updated_record.given_name.must_equal "New"
			end

			it 'must not update any fields that were not included in the data' do
				@updated_record.phone.must_equal @person.phone
			end

		end

		describe 'error conditions' do

			it 'must raise an ArgumentError if the username is attempted to be updated' do
				data = Hash("username" => "newusername")
				assert_raises ArgumentError do
					Gabb::PersonService.update_person @person, data
				end
			end

			it 'must raise a RuntimeError if the data includes an email address that already exists' do
				another_person = create(:person, username: SecureRandom.hex, email: "#{SecureRandom.hex}@test.com")
				data = Hash("email" => another_person.email)
				assert_raises RuntimeError do
					Gabb::PersonService.update_person @person, data
				end
			end

			it 'must not raise a RuntimeError if the email address equals the persons email address' do
				data = Hash("email" => @person.email)
				Gabb::PersonService.update_person @person, data
			end

		end

	end

	describe 'get people' do

		before do
			@person = build(:person, given_name: "Joe", family_name: "Person", username: SecureRandom.hex)
		end

		it 'must get all of the people if no parameters are given' do
			people = Gabb::PersonService.get_people
			people.length.must_equal Gabb::Person.count
		end

		it 'must filter the records by username when it is passed in as a parameter' do
			num_people = Gabb::Person.where({username: "#{@person.username}"}).count
			params = Hash["username", @person.username]
			people = Gabb::PersonService.get_people params
			people.length.must_equal num_people
		end

		it 'must filter the records by username and given name when both are passed in as a parameter' do
			num_people = Gabb::Person.where({username: "#{@person.username}", given_name: "Joe", family_name: "Person"}).count
			params = Hash["username", @person.username, "given_name", "Joe"]
			people = Gabb::PersonService.get_people params
			people.length.must_equal num_people
		end

	end

	describe 'search' do

		describe 'simple search' do

			describe 'create query for search term' do

				it 'must return a Mongoid Selector' do
					query = Gabb::PersonService.create_query_for_search_term "Evan"
					query.must_be_instance_of Mongoid::Criteria
				end

				it 'must search a single term for matches against given name, family name and username' do
					query = Gabb::PersonService.create_query_for_search_term "Evan"
					query.selector.must_equal Hash("$or"=>[{"given_name"=>/Evan/}, {"family_name"=>/Evan/}, {"username"=>/Evan/}])
				end

				it 'must search two terms separated by a + against the given and family name, or the family and given name' do
					query = Gabb::PersonService.create_query_for_search_term "Evan+Waters"
					query.selector.must_equal Hash("$or"=>[{"given_name"=>/Evan/, "family_name"=>/Waters/}, {"given_name"=>/Waters/, "family_name"=>/Evan/}])
				end

				describe 'perform a search' do

					it 'must return an array of people' do
						params = Hash("term" => "Eva")
						people = Gabb::PersonService.search_people params
						people[0].must_be_instance_of Gabb::Person
					end

					it 'must return partial matches of a single term with given name' do
						person = create(:person, username: SecureRandom.hex, given_name: SecureRandom.hex)
						term = person.given_name[0..2]
						params = Hash("term" => "#{term}")
						people = Gabb::PersonService.search_people params
						people.must_include person
					end

					it 'must return partial matches of a single term with family name' do
						person = create(:person, username: SecureRandom.hex, family_name: SecureRandom.hex)
						term = person.family_name[0..2]
						params = Hash("term" => "#{term}")
						people = Gabb::PersonService.search_people params
						people.must_include person
					end

					it 'must return partial matches of a single term with username' do
						person = create(:person, username: SecureRandom.hex)
						term = person.username[0..(person.username.length - 2)]
						params = Hash("term" => "#{term}")
						people = Gabb::PersonService.search_people params
						people.must_include person
					end

					it 'must find matches of multiple terms by if the first two match given_name and family_name' do
						person = create(:person, username: SecureRandom.hex, given_name: SecureRandom.hex, family_name: SecureRandom.hex)
						term1 = person.given_name[0..2]
						term2 = person.family_name[0..2]
						params = Hash("term" => "#{term1}+#{term2}")
						people = Gabb::PersonService.search_people params
						people.must_include person
					end

					it 'must find matches of multiple terms by if the first two match family_name and given_name' do
						person = create(:person, username: SecureRandom.hex, given_name: SecureRandom.hex, family_name: SecureRandom.hex)
						term1 = person.given_name[0..2]
						term2 = person.family_name[0..2]
						params = Hash("term" => "#{term2}+#{term1}")
						people = Gabb::PersonService.search_people params
						people.must_include person
					end

					it 'must limit the number of results returned by a limit parameter if it is presented' do
						person1 = create(:person, username: SecureRandom.hex, family_name: "Test")
						person2 = create(:person, username: SecureRandom.hex, family_name: "Test")
						params = Hash("term" => "Test", "limit" => 1)
						people = Gabb::PersonService.search_people params
						people.count.must_equal 1
					end

				end

			end

		end

	end

	describe 'find people from list of emails' do

		before do
			@personA = create(:person, username: SecureRandom.hex, email: "person1@google.com")
			@personB = create(:person, username: SecureRandom.hex, email: "person2@google.com")
			@personC = create(:person, username: SecureRandom.hex, email: "person3@google.com")
			@personD = create(:person, username: SecureRandom.hex, email: "person4@google.com")

			@email_array = ["person1@google.com", "person2@google.com", "person@yahoo.com", "person@hotmail.com", "person4@google.com"]

			@people = Gabb::PersonService.find_people_from_list_of_emails @email_array
		end

		it 'must return an array of people' do
			@people[0].must_be_instance_of Gabb::Person
		end

		it 'must return all people who have a matching email' do
			@people.count.must_equal 3
		end

	end

	describe 'check field availability' do

		describe 'look for a field that can be checked (username, email, phone)' do

			describe 'search for a username that is available' do

					before do
						params = Hash["username", "availableusername"]
						@result = Gabb::PersonService.check_field_availability params
					end

					it 'must return a hash indicating that the field is avilable' do
						@result.must_equal Hash["username", "available"]
					end

			end

			it 'must check phone numbers' do
				params = Hash["phone", "availablephone"]
				result = Gabb::PersonService.check_field_availability params
				result.must_equal Hash["phone", "available"]
			end

			it 'must check phone emails' do
				params = Hash["email", "availableemail"]
				result = Gabb::PersonService.check_field_availability params
				result.must_equal Hash["email", "available"]
			end

			it 'if a field is already used, it must indicate that it is unavailble' do
				person = create(:person, username: SecureRandom.hex)
				params = Hash["username", person.username]
				result = Gabb::PersonService.check_field_availability(params)
				result.must_equal Hash["username", "unavailable"]
			end

		end

		describe 'invalid parameters' do

			it 'must raise a RuntimeError if more than one field is submitted' do
				params = Hash["username", "user", "phone", "555"]
				assert_raises RuntimeError do
					Gabb::PersonService.check_field_availability params
				end
			end

			it 'must raise an RuntimeError if the parameters include a field that cannot be checked' do
				params = Hash["name", "A Name"]
				assert_raises RuntimeError do
					Gabb::PersonService.check_field_availability params
				end
			end

		end

	end

end
