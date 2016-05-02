module Gabb
  class ChatService

    def self.chats payload, params
      Gabb::Chat.where(params).order_by(created_at: 'desc').to_a
    end

    def self.create_chat payload, data
      person = Gabb::Person.find(payload["id"])
      chat = person.chats.create! data
      Gabb::ChatService.send_chat_notification chat
      chat
    end

    def self.people_to_notify_for_chat chat
      people = []
      Gabb::Chat.where(podcast_id: chat.podcast_id).each { |c| people << c.person }
      people.uniq.select { |person| person.device_token != nil && person.id != chat.person.id }
    end

    def self.send_chat_notification chat
      people = Gabb::ChatService.people_to_notify_for_chat chat
      notifications = []
      people.each do |person|
        notifications << APNS::Notification.new(person.device_token, alert: "#{chat.person.full_name}: #{chat.text}", badge: nil, other: { uri: chat.uri, podcast_id: chat.podcast_id })
      end
      APNS.send_notifications notifications
    end

  end
end
