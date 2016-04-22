module Gabb
  class SessionService

    def self.start_session payload, data
      person = Gabb::Person.find(payload["id"])
      hash = Hash(episode_url: data["episode_url"], episode_hash: data["episode_hash"], start_time_scale: data["time_scale"], start_time_value: data["time_value"])
      person.sessions.create! hash
    end

    def self.stop_session payload, data
      person = Gabb::Person.find(payload["id"])
      session = person.sessions.where(episode_hash: data["episode_hash"]).order_by(created_at: 'desc').first

      if session && !session.stop_time_value
        hash = Hash(stop_time_scale: data["time_scale"], stop_time_value: data["time_value"])
        session.update_attributes hash
      else
        hash = Hash(episode_url: data["episode_url"], episode_hash: data["episode_hash"], stop_time_scale: data["time_scale"], stop_time_value: data["time_value"])
        session = person.sessions.create! hash
      end

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

  end

end
