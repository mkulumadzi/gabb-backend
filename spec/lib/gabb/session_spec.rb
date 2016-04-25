require_relative '../../spec_helper'

describe Gabb::Session do

  before do
    @person = create(:person, username: SecureRandom.hex)
    @session = @person.sessions.new(attributes_for(:session))
  end

  describe 'create a session' do

    it 'must be a session' do
      @session.must_be_instance_of Gabb::Session
    end

    it 'must store the fields' do
      @session.podcast_id.must_equal attributes_for(:session)[:podcast_id]
      @session.title.must_equal attributes_for(:session)[:title]
      @session.episode_url.must_equal attributes_for(:session)[:episode_url]
      @session.episode_hash.must_equal attributes_for(:session)[:episode_hash]
      @session.start_time_scale.must_equal attributes_for(:session)[:start_time_scale]
      @session.start_time_value.must_equal attributes_for(:session)[:start_time_value]
      @session.stop_time_scale.must_equal attributes_for(:session)[:stop_time_scale]
      @session.stop_time_value.must_equal attributes_for(:session)[:stop_time_value]
    end

  end

  describe 'uri' do

    it 'must return a valid uri for the session' do
      assert_match(/#{ENV['GABB_BASE_URL']}\/session\/id\/\w{24}/, @session.uri)
    end

  end

  describe 'as json' do

    it 'must return a parseable json document' do
      JSON.parse(@session.as_json).must_be_instance_of Hash
    end

  end

end
