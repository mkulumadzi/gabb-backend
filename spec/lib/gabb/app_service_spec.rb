# require 'rack/test'
require_relative '../../spec_helper'

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe Gabb::AppService do

  before do
    @person1 = create(:person, username: SecureRandom.hex)
    @person2 = create(:person, username: SecureRandom.hex)
    @person3 = create(:person, username: SecureRandom.hex)

    @admin_token = Gabb::AuthService.get_admin_token
    @app_token = Gabb::AuthService.get_app_token
    @person1_token = Gabb::AuthService.generate_token_for_person @person1
    @person2_token = Gabb::AuthService.generate_token_for_person @person2
  end

  describe 'get token from authorization header' do

    it 'must return the token if one is provided' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      Gabb::AppService.get_token_from_authorization_header(last_request).must_equal @admin_token
    end

    it 'must return nil if no token was provided' do
      get "/"
      Gabb::AppService.get_token_from_authorization_header(last_request).must_equal nil
    end

  end

  describe 'get payload from request bearer' do

    describe 'get a valid token' do

      before do
        get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
        @payload = Gabb::AppService.get_payload_from_authorization_header last_request
      end

      it 'must get return the payload of the auth token included in the header as a hash' do
        @payload.must_be_instance_of Hash
      end

      it 'must include the scope in the payload' do
        @payload["scope"].must_equal Gabb::AuthService.get_scopes_for_user_type "admin"
      end

    end

    describe 'invalid tokens' do

      it 'must return a message if the token has expired' do
        expiring_payload = { :data => "test", :exp => Time.now.to_i - 60 }
        expiring_token = Gabb::AuthService.generate_token expiring_payload
        get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{expiring_token}"}

        Gabb::AppService.get_payload_from_authorization_header(last_request).must_equal "Token expired"
      end

      it 'must return an error message if the token is invalid' do
        invalid_token = "abc.123.def"
        get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{invalid_token}"}

        Gabb::AppService.get_payload_from_authorization_header(last_request).must_equal "Token is invalid"
      end

      it 'must raise an error message if the token is not signed by the correct certificate' do
        rsa_private = OpenSSL::PKey::RSA.generate 2048
        payload = { :data => "test" }
        token = JWT.encode payload, rsa_private, 'RS256'
        get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}

        Gabb::AppService.get_payload_from_authorization_header(last_request).must_equal "Invalid token signature"
      end

      it 'must return an error message if the Authorization header is not provided' do
        get "/"
        Gabb::AppService.get_payload_from_authorization_header(last_request).must_equal "No token provided"
      end

    end

  end

  describe 'check authorization' do

    it 'must return false if the request Authorization includes the required scope' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      Gabb::AppService.unauthorized?(last_request, "admin").must_equal false
    end

    it 'must return true if the request Authorization does not include the required scope' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@app_token}"}
      Gabb::AppService.unauthorized?(last_request, "admin").must_equal true
    end

    it 'must return true if no Authorization header is submitted' do
      get "/"
      Gabb::AppService.unauthorized?(last_request, "admin").must_equal true
    end

    it 'must return true is the token has been marked as invalid in the database' do
      token = Gabb::AuthService.get_test_token
      db_token = Gabb::Token.create(value: token, is_invalid: true)
      db_token.save
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
      Gabb::AppService.unauthorized?(last_request, "admin").must_equal true
    end

  end

  describe 'check authorized ownership' do

    it 'must return true if the token has been marked as invalid' do
      db_token = Gabb::Token.create(value: @person1_token, is_invalid: true)
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_authorized_owner?(last_request, "can-read", @person1.id.to_s).must_equal true
    end

    it 'must return false if the person_id is in the payload and it has the required scope' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_authorized_owner?(last_request, "can-read", @person1.id.to_s).must_equal false
    end

    it 'must return true if the person_id is in the payload but it does not have the required scope' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_authorized_owner?(last_request, "create-person", @person1.id.to_s).must_equal true
    end

    it 'must return true if the person_id is not in the payload' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_authorized_owner?(last_request, "can-read", @person2.id.to_s).must_equal true
    end

  end

  describe 'check admin or ownership' do

    it 'must return false if the token has the admin scope' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      Gabb::AppService.not_admin_or_owner?(last_request, "can-read", @person1.id.to_s).must_equal false
    end

    it 'must return false if the person_id is in the token and the scope is correct' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_admin_or_owner?(last_request, "can-read", @person1.id.to_s).must_equal false
    end

    it 'must return true if the token does not include the required scope and is not admin' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_admin_or_owner?(last_request, "reset-password", @person1.id.to_s).must_equal true
    end

    it 'must return true if it is the wrong person' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@person1_token}"}
      Gabb::AppService.not_admin_or_owner?(last_request, "can-read", @person2.id.to_s).must_equal true
    end

  end

  describe 'get API version from content-type header' do

    it 'must parse the version from the CONTENT_TYPE header if the header begins with application/vnd.Gabb' do
        get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}", "CONTENT_TYPE" => "application/vnd.Gabb.v2+json"}
        Gabb::AppService.get_api_version_from_content_type(last_request).must_equal "v2"
    end

    it 'must return V1 if the version is not included in the CONTENT_TYPE header' do
      get "/", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_token}"}
      Gabb::AppService.get_api_version_from_content_type(last_request).must_equal "v1"
    end

  end

  describe 'add updated since to query' do

    before do
      @query = Gabb::Person.where(given_name: "test")
    end

    describe 'params include updated_at' do

      before do
        @params = Hash(updated_at: { "$gt" => (Time.now + 4.minutes) })
        @query = Gabb::AppService.add_updated_since_to_query @query, @params
      end

      it 'must have added updated_at to the query' do
        @query.selector["updated_at"].must_equal @params[:updated_at]
      end

      it 'must have preserved the original parts of the query' do
        @query.selector.keys.must_equal ["given_name", "updated_at"]
      end

    end

    describe 'params do not include updated_at' do

      before do
        params = Hash.new
        @query = Gabb::AppService.add_updated_since_to_query @query, params
      end

      it 'must not have added updated_at to the query' do
        @query.selector.keys.include?("updated_at").must_equal false
      end

    end

  end

  describe 'convert objects to documents' do

    before do
      array = [@person1, @person2, @person3]
      @documents = Gabb::AppService.convert_objects_to_documents array
    end

    it 'must return Hash documents' do
      @documents[0].must_be_instance_of Hash
    end

    it 'must convert the objects to these documents' do
      @documents[0].must_equal @person1.as_document
    end

    it 'must return all of the documents' do
      @documents.count.must_equal 3
    end

  end

  describe 'email enabled?' do

    it 'must return true if sending email is enabled' do
      ENV['GABB_EMAIL_ENABLED'] = 'yes'
      Gabb::AppService.email_enabled?.must_equal true
    end

    it 'must return false if sending email is not enabled' do
      ENV['GABB_EMAIL_ENABLED'] = 'no'
      Gabb::AppService.email_enabled?.must_equal false
    end

  end

  describe 'email api key' do

    it 'must return the test key for test requests' do
      get '/?test=true'
      Gabb::AppService.email_api_key(last_request).must_equal "POSTMARK_API_TEST"
    end

    it 'must return the api key for real requests' do
      get '/'
      Gabb::AppService.email_api_key(last_request).must_equal ENV["POSTMARK_API_KEY"]
    end

  end

  describe 'send authorization email if enabled' do

    before do
      @person = build(:person, username: SecureRandom.hex)
      get '/?test=true' # Create a dummy get request to generate the test api key
    end

    describe 'email is enabled' do

      before do
        ENV['GABB_EMAIL_ENABLED'] = 'yes'
        ENV['GABB_POSTMARK_EMAIL_ADDRESS'] = "test@test.com"
        @result = Gabb::AppService.send_authorization_email_if_enabled(@person, last_request)
      end

      it 'must return a Hash with "to" addressed to the test user email' do
        @result[:to].must_equal @person.email
      end

      it 'must have 0 for the error code' do
        @result[:error_code].must_equal 0
      end

    end

    describe 'email is not enabled' do

      it 'must return nil' do
        ENV['GABB_EMAIL_ENABLED'] = 'no'
        Gabb::AppService.send_authorization_email_if_enabled(@person, last_request).must_equal nil
      end

    end

  end

  describe 'send validation email for email change if enabled' do

    before do
      @person = build(:person, username: SecureRandom.hex)
      @person.mark_email_as_valid
      get '/?test=true' # Create a dummy get request to generate the test api key
    end

    describe 'email is enabled' do

      before do
        ENV['GABB_EMAIL_ENABLED'] = 'yes'
        ENV['GABB_POSTMARK_EMAIL_ADDRESS'] = "test@test.com"
      end

      describe 'email address has changed' do

        before do
          old_email = "old_email@test.com"
          @result = Gabb::AppService.send_validation_email_for_email_change_if_enabled @person, last_request, old_email
        end

        it 'must return a Hash with "to" addressed to the test user email' do
          @result[:to].must_equal @person.email
        end

        it 'must have 0 for the error code' do
          @result[:error_code].must_equal 0
        end

        it 'must have marked the person as having an unvalidated email address' do
          db_person = Gabb::Person.find(@person.id)
          db_person.email_address_validated.must_equal false
        end

      end

    end

    describe 'email is not enabled' do

      it 'must return nil' do
        ENV['GABB_EMAIL_ENABLED'] = 'no'
        Gabb::AppService.send_validation_email_for_email_change_if_enabled @person, last_request, "not_email@test.com"
      end

    end

  end

  describe 'send password reset email if enabled' do

    before do
      @person = build(:person, username: SecureRandom.hex)
      get '/?test=true' # Create a dummy get request to generate the test api key
    end

    describe 'email is enabled' do

      before do
        ENV['GABB_EMAIL_ENABLED'] = 'yes'
        ENV['GABB_POSTMARK_EMAIL_ADDRESS'] = "test@test.com"
        @result = Gabb::AppService.send_password_reset_email_if_enabled(@person, last_request)
      end

      it 'must return a Hash with "to" addressed to the test user email' do
        @result[:to].must_equal @person.email
      end

      it 'must have 0 for the error code' do
        @result[:error_code].must_equal 0
      end

    end

    describe 'email is not enabled' do

      it 'must return and empty hash' do
        ENV['GABB_EMAIL_ENABLED'] = 'no'
        Gabb::AppService.send_password_reset_email_if_enabled(@person, last_request).must_equal Hash.new
      end

    end

  end

  describe 'json document for people documents' do

    it 'must return a json document from the people documents, minus the fields that should be omitted' do

      person1 = build(:person, username: SecureRandom.hex, facebook_id: "abc")
      person2 = build(:person, username: SecureRandom.hex, facebook_id: "def")
      people_array = [person1, person2]
      documents = Gabb::AppService.convert_objects_to_documents people_array
      result = Gabb::AppService.json_document_for_people_documents documents

      result.must_equal documents.to_json( :except => ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token"] )

    end

  end

end
