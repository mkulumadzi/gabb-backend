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

  end
end
