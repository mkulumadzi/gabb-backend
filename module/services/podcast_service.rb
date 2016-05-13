module Gabb
  class PodcastService

    def self.listening_to payload, params
      person = Gabb::Person.find(payload["id"])
      podcasts = person.sessions.order_by(updated_at: 'desc').distinct("podcast")
      sessions = []
      for i in 0...podcasts.count
        podcast = podcasts[i]
        sessions << person.sessions.where(podcast: podcast).order_by(updated_at: 'desc').first
      end

      sessions = sessions.sort {|a, b| b.updated_at <=> a.updated_at }

      podcasts = []
      sessions.each { |s| podcasts << s.podcast }

      podcasts
    end

    def self.get_detailed_podcast_info payload, params
      person = Gabb::Person.find(payload["id"])
      podcast = Gabb::PodcastService.get_podcast params["id"]
      podcast["recent_episodes"] = Gabb::PodcastService.add_session_info_to_podcast_episodes podcast["recent_episodes"], person
      podcast
    end

    def self.add_session_info_to_podcast_episodes episodes, person
      episodes.each do |e|
        session = person.sessions.where(episode_url: e["audio_url"]).order_by(created_at: 'desc').first
        if session
          session_hash = Hash("start_time_value" => session[:start_time_value], "start_time_scale" => session[:start_time_scale], "stop_time_value" => session[:stop_time_scale], "stop_time_scale" => session[:stop_time_value])
          e["last_session"] = session_hash
        end
      end
      episodes
    end

    def self.get_basic_podcast_info podcast_id
      podcast = Gabb::PodcastService.get_podcast podcast_id
      Hash("title" => podcast["title"], "podcast_id" => podcast["podcast_id"], "feed_url" => podcast["feed_url"], "image_url" => podcast["image_url"] )
    end

    def self.get_podcast podcast_id
      client_key = "3475d9da221dca830b1cde44a4079bed"
      podcast_url = "https://feedwrangler.net/api/v2/podcasts/show?podcast_id=#{podcast_id}&client_key=#{client_key}"
      podcast = JSON.parse(HTTParty.get(podcast_url).body)["podcast"]
    end

    def self.podcasts_with_chats payload, params
      person = Gabb::Person.find(payload["id"])
      podcast_ids = person.chats.order_by(updated_at: 'desc').distinct("podcast_id")

      chats = []
      for i in 0...podcast_ids.count
        chats << Gabb::Chat.where(podcast_id: podcast_ids[i]).order_by(updated_at: 'desc').first
      end

      chats = chats.sort { |a, b| b.updated_at <=> a.updated_at }

      podcasts = []
      chats.each { |c| podcasts << Gabb::PodcastService.get_basic_podcast_info(c.podcast_id) }
      podcasts
    end

  end
end
