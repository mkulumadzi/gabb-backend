module Gabb
  class SessionService

    def self.start_session payload, data
      person = Gabb::Person.find(payload["id"])
      hash = Hash(podcast: data["podcast"], title: data["title"], episode_url: data["episode_url"], episode_hash: data["episode_hash"], start_time_scale: data["time_scale"], start_time_value: data["time_value"])
      person.sessions.create! hash
    end

    def self.stop_session payload, data
      person = Gabb::Person.find(payload["id"])
      session = person.sessions.where(episode_hash: data["episode_hash"]).order_by(created_at: 'desc').first

      if session && !session.stop_time_value
        hash = Hash(stop_time_scale: data["time_scale"], stop_time_value: data["time_value"])
        session.update_attributes hash
      else
        hash = Hash(podcast: data["podcast"], title: data["title"], episode_url: data["episode_url"], episode_hash: data["episode_hash"], stop_time_scale: data["time_scale"], stop_time_value: data["time_value"])
        session = person.sessions.create! hash
      end

      session
    end

    def self.finish_session payload, data
      session = Gabb::SessionService.stop_session payload, data
      session.finished = true
      session.save
      session
    end

    def self.last_session payload, params
      person = Gabb::Person.find(payload["id"])

      if params["episode_hash"]
        session = person.sessions.where(episode_hash: params["episode_hash"]).order_by(created_at: 'desc').first
      else
        session = person.sessions.order_by(created_at: 'desc').first
      end
      session
    end

    def self.sessions payload, params
      person = Gabb::Person.find(payload["id"])

      # Hacky way to get distinct most recent sessions, since I can't figure out how to get the Mongoid aggregate function to work.
      episode_hashes = person.sessions.distinct("episode_hash")
      sessions = []
      for i in 0...episode_hashes.count
        episode_hash = episode_hashes[i]
        sessions << person.sessions.where(episode_hash: episode_hash).order_by(updated_at: 'desc').first
      end

      sessions = sessions.sort {|a, b| b.updated_at <=> a.updated_at }

      limit = params["limit"] ? params["limit"].to_i : 25
      limit = (episode_hashes.count < limit) ? episode_hashes.count : limit

      sessions.first(limit)
    end

  end

end
