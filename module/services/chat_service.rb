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

    def self.send_chat_notification chat
      people = Gabb::Person.where(:device_token.ne => nil)
      notifications = []
      people.each do |person|
        notifications << APNS::Notification.new(person.device_token, alert: chat.text, badge: nil, other: { chat_id: chat.id })
      end
      APNS.send_notifications notifications
    end

  end
end
