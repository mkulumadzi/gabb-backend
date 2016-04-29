require_relative '../../spec_helper'

describe Gabb::Chat do

  before do
    @person = create(:person, username: SecureRandom.hex)
    @chat = @person.chats.new(attributes_for(:chat))
  end

  describe 'create a chat' do

    it 'must be a chat' do
      @chat.must_be_instance_of Gabb::Chat
    end

    it 'must store the fields' do
      @chat.text.must_equal attributes_for(:chat)[:text]
      @chat.podcast_id.must_equal attributes_for(:chat)[:podcast_id]
    end

  end

  describe 'uri' do

    it 'must return a valid uri for the session' do
      assert_match(/#{ENV['GABB_BASE_URL']}\/chat\/id\/\w{24}/, @chat.uri)
    end

  end

  describe 'default json' do

    it 'must return a parseable json document, and must return the appropriate fields' do
      hash = JSON.parse(@chat.default_json)
      hash["text"].must_equal @chat.text
      hash["podcast_id"].must_equal @chat.podcast_id
      hash["person_id"].must_equal nil

      person = hash["from_person"]
      person["given_name"].must_equal @person.given_name
      person["family_name"].must_equal @person.family_name

      person["salt"].must_equal nil
      person["hashed_password"].must_equal nil
      person["device_token"].must_equal nil
      person["facebook_id"].must_equal nil
      person["facebook_token"].must_equal nil
      person["email_address_validated"].must_equal nil
    end

  end

end
