require_relative '../../spec_helper'

describe Gabb::SessionService do

  before do
    @person = create(:person, username: SecureRandom.hex)
    @payload = Hash("id" => @person.id)
  end

  describe 'start session' do

    it 'must create a new session if the data and payload is valid and save it to the database' do
      data = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => 515135135)
      session = Gabb::SessionService.start_session @payload, data
      session.podcast_id.must_equal data["podcast_id"]
      session.title.must_equal data["title"]
      session.episode_url.must_equal data["episode_url"]
      session.episode_hash.must_equal data["episode_hash"]
      session.start_time_scale.must_equal data["time_scale"]
      session.start_time_value.must_equal data["time_value"]
      @person.sessions.where(id: session.id).count.must_equal 1
    end

  end

  describe 'stop session' do

    it 'must update an existing session if it exists' do

      start_data = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => 515135135)
      start_session = Gabb::SessionService.start_session @payload, start_data

      session_count = @person.sessions.count

      stop_data = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => 987135135)
      stop_session = Gabb::SessionService.stop_session @payload, stop_data

      session_count.must_equal @person.sessions.count
      start_session.id.must_equal stop_session.id

      stop_session.stop_time_scale.must_equal stop_data["time_scale"]
      stop_session.stop_time_value.must_equal stop_data["time_value"]
    end

    it 'must create a new session if it does not exist for that episode hash' do
      start_data = Hash("podcast_id" => 2, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "defghadfa", "time_scale" => 1000000, "time_value" => 515135135)
      start_session = Gabb::SessionService.start_session @payload, start_data

      session_count = @person.sessions.count

      stop_data = Hash("podcast_id" => 3, "title" => "A podcast", "episode_url" => "http://apodcast.com/podcast", "episode_hash" => "asdfafda", "time_scale" => 1000000, "time_value" => 987135135)
      stop_session = Gabb::SessionService.stop_session @payload, stop_data

      @person.sessions.count.must_equal session_count + 1
    end

  end

  describe 'last session' do

    before do
      @session1 = @person.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session2 = @person.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session3 = @person.sessions.create!(Hash(episode_hash: "barfoo"))
    end

    it 'must return the last session for an episode hash if it is given' do
      session = Gabb::SessionService.last_session @payload, Hash("episode_hash" => "foobar")
      session.must_equal @session2
    end

    it 'must return the last session for if not episode hash is given' do
      session = Gabb::SessionService.last_session @payload, Hash.new()
      session.must_equal @session3
    end

  end

  describe 'sessions' do

    before do
      @session1 = @person.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session2 = @person.sessions.create!(Hash(episode_hash: "foobar"))
      sleep(0.1)
      @session3 = @person.sessions.create!(Hash(episode_hash: "barfoo"))
      sleep(0.1)
      @session3 = @person.sessions.create!(Hash(episode_hash: "fortran"))
    end

    it 'must return the most recent session for each episode hash' do
        sessions = Gabb::SessionService.sessions @payload, Hash.new()
        sessions.count.must_equal 3
        (sessions.select { |a| a.episode_hash == "foobar" }).count.must_equal 1
        (sessions.select { |a| a.episode_hash == "barfoo" }).count.must_equal 1
        (sessions.select { |a| a.episode_hash == "fortran" }).count.must_equal 1
        (sessions.select { |a| a.episode_hash == "foobar" })[0].must_equal @session2
    end

    it 'must limit the number of sessions returned if a limit is given' do
      sessions = Gabb::SessionService.sessions @payload, Hash("limit" => 2)
      sessions.count.must_equal 2
      (sessions.select { |a| a.episode_hash == "foobar" }).count.must_equal 0
      (sessions.select { |a| a.episode_hash == "barfoo" }).count.must_equal 1
      (sessions.select { |a| a.episode_hash == "fortran" }).count.must_equal 1
    end

  end

end
