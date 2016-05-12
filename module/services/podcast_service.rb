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

    def self.get_podcast podcast_id
      client_key = "3475d9da221dca830b1cde44a4079bed"
      podcast_url = "https://feedwrangler.net/api/v2/podcasts/show?podcast_id=#{podcast_id}&client_key=#{client_key}"
      JSON.parse(HTTParty.get(podcast_url).body)
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
      chats.each { |c| podcasts << Gabb::PodcastService.get_podcast(c.podcast_id) }
      podcasts
    end

  end
end
