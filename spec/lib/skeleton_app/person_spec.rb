require_relative '../../spec_helper'

describe SkeletonApp::Person do

	before do
		@person = create(:person, username: SecureRandom.hex)
		@expected_attrs = attributes_for(:person)
	end

	describe 'create a person' do

		describe 'store the fields' do

			it 'must create a new person record' do
				@person.must_be_instance_of SkeletonApp::Person
			end

			it 'must store the username' do
				@person.username.must_be_instance_of String
			end

			it 'must thrown an error if a record is submitted with a duplicate username' do
				person = create(:person, username: SecureRandom.hex)
				assert_raises(Mongo::Error::OperationFailure) {
					SkeletonApp::Person.create!(
						username: person.username,
						given_name: "test",
						family_name: "user",
						email: "test@test.com",
						phone: "5554441234"
					)
				}
			end

			it 'must store the given_name' do
				@person.given_name.must_equal @expected_attrs[:given_name]
			end

			it 'must store the family_name' do
				@person.family_name.must_equal @expected_attrs[:family_name]
			end

			it 'must store the email' do
				@person.email.must_equal @expected_attrs[:email]
			end

			it 'must store whether the email address was validated' do
				@person.email_address_validated.must_equal @expected_attrs[:email_address_validated]
			end

			it 'must store the phone' do
				@person.phone.must_equal @expected_attrs[:phone]
			end

			it 'must store the salt' do
				@person.salt.must_equal @expected_attrs[:salt]
			end

			it 'must store the hashed password' do
				@person.hashed_password.must_equal @expected_attrs[:hashed_password]
			end

			it 'must store the device token' do
				@person.device_token.must_equal @expected_attrs[:device_token]
			end

			it 'must store the facebook id' do
				@person.facebook_id.must_equal @expected_attrs[:facebook_id]
			end

			it 'must store the facebook token' do
				@person.facebook_token.must_equal @expected_attrs[:facebook_token]
			end

		end

	end

	describe 'initials' do

		it 'must return the initials if both given_name and family_name are available' do
			person = build(:person, given_name: "Test", family_name: "User")
			person.initials.must_equal "TU"
		end

		it 'must return the first two letters of the given name if the family name is not entered' do
			person = build(:person, given_name: "Test", family_name: nil)
			person.initials.must_equal "Te"
		end

		it 'must return the first two letters of the family name if the given name is not entered' do
			person = build(:person, given_name: nil, family_name: "User")
			person.initials.must_equal "Us"
		end

		it 'must return an empty string if no names are entered' do
			person = build(:person, given_name: nil, family_name: nil)
			person.initials.must_equal ""
		end

	end

	describe 'full name' do

		it 'must concatenate the given_name and family_name if both are availble' do
			person = build(:person, username: SecureRandom.hex, given_name: "Test", family_name: "Person")
			person.full_name.must_equal "Test Person"
		end

		it 'must return the given name if only it is available' do
			person = build(:person, username: SecureRandom.hex, given_name: "Test", family_name: nil)
			person.full_name.must_equal "Test"
		end

		it 'must family_name if only it is availble' do
			person = build(:person, username: SecureRandom.hex, given_name: nil, family_name: "Person")
			person.full_name.must_equal "Person"
		end

	end

	describe 'mark email as valid' do

		before do
			@person.mark_email_as_valid
		end

		it 'must have marked the email address as valid' do
			@person.email_address_validated.must_equal true
		end

		it 'must have saved the changes' do
			person = SkeletonApp::Person.find(@person.id)
			person.email_address_validated.must_equal true
		end

	end

	describe 'uri' do

		it 'must return a valid uri for the person' do
  		assert_match(/#{ENV['SKELETON_APP_BASE_URL']}\/person\/id\/\w{24}/, @person.uri)
		end

	end

	describe 'as json' do

		before do
			@person = build(:person, username: SecureRandom.hex)
			@person.hashed_password = "abc"
			@person.salt = "def"
			@person.facebook_id = "123"
			@person.device_token = "456"
			@json_document = @person.as_json
			@parsed_document = JSON.parse(@json_document)
		end

		it 'must return a parseable json document' do
			@parsed_document.must_be_instance_of Hash
		end

		it 'must include the person info' do
			@parsed_document["username"].must_equal @person.username
		end

		it 'must not include the salt' do
			@parsed_document["salt"].must_equal nil
		end

		it 'must not include the hashed_password' do
			@parsed_document["hashed_passwords"].must_equal nil
		end

		it 'must not include the device_token' do
			@parsed_document["device_token"].must_equal nil
		end

		it 'must not include the facebook_id' do
			@parsed_document["facebook_id"].must_equal nil
		end

		it 'must not include the facebook token' do
			@parsed_document["facebook_token"].must_equal nil
		end

	end

end
