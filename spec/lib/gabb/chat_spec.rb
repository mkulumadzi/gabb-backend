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

  describe 'as json' do

    it 'must return a parseable json document' do
      JSON.parse(@chat.as_json).must_be_instance_of Hash
    end

  end

end
