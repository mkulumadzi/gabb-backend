require_relative '../../spec_helper'

describe Gabb::Session do

  before do
    @person = create(:person, username: SecureRandom.hex)
    @session = @person.sessions.new(attributes_for(:session))
    @podcast = Hash(podcast_id: 2, image_url: "http://example.com/image.jpg", title: "Awesome podcast", feed_url: "http://example.com/feed")
    @session.podcast = @podcast
  end

  describe 'create a session' do

    it 'must be a session' do
      @session.must_be_instance_of Gabb::Session
    end

    it 'must store the fields' do
      @session.podcast.must_equal @podcast
      @session.title.must_equal attributes_for(:session)[:title]
      @session.episode_url.must_equal attributes_for(:session)[:episode_url]
      @session.episode_hash.must_equal attributes_for(:session)[:episode_hash]
      @session.start_time_scale.must_equal attributes_for(:session)[:start_time_scale]
      @session.start_time_value.must_equal attributes_for(:session)[:start_time_value]
      @session.stop_time_scale.must_equal attributes_for(:session)[:stop_time_scale]
      @session.stop_time_value.must_equal attributes_for(:session)[:stop_time_value]
    end

  end

  # describe 'embed podcast info' do
  #
  #   it 'must embed podcast info' do
  #     @session.podcast_info = build(:podcast_info)
  #     @session.podcast_info.must_be_instance_of Gabb::PodcastInfo
  #
  #     attrs = attributes_for(:podcast_info)
  #     @session.podcast_info[:podcast_id].must_equal attrs[:podcast_id]
  #     @session.podcast_info[:image_url].must_equal attrs[:image_url]
  #     @session.podcast_info[:feed_url].must_equal attrs[:feed_url]
  #     @session.podcast_info[:title].must_equal attrs[:title]
  #   end
  #
  # end

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
