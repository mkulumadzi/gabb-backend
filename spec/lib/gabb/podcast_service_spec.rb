require_relative '../../spec_helper'

describe Gabb::PodcastService do

  before do

    @podcast1 = Hash("podcast_id" => 1, "title" => "Awesome podcast", "image_url" => "http://example.com/image.jpg", "feed_url" => "http://example.com/podcast/feed")
    @podcast2 = Hash("podcast_id" => 2, "title" => "Awesome podcast", "image_url" => "http://example.com/image.jpg", "feed_url" => "http://example.com/podcast/feed")

    @person = create(:person, username: SecureRandom.hex)
    @payload = Hash("id" => @person.id)

    @session1 = @person.sessions.create!(Hash(episode_hash: "foobar", podcast: @podcast1))

    sleep(0.1)
    @session2 = @person.sessions.create!(Hash(episode_hash: "foobar", podcast: @podcast1))

    sleep(0.1)
    @session3 = @person.sessions.create!(Hash(episode_hash: "barfoo", podcast: @podcast1))

    sleep(0.1)
    @session4 = @person.sessions.create!(Hash(episode_hash: "fortran", podcast: @podcast2))
  end

  describe 'listening to' do

    it 'must return the podcasts the person has been listening to, in descending order of most recently listened to' do
      # binding.pry
      podcasts = Gabb::PodcastService.listening_to @payload, Hash.new()
      podcasts.count.must_equal 2
      podcasts[0].must_equal @podcast2
      podcasts[1].must_equal @podcast1
    end

  end

end
