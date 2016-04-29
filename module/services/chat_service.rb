module Gabb
  class ChatService

    def self.chats payload, params
      Gabb::Chat.where(params).order_by(created_at: 'desc').to_a
    end

    def self.create_chat payload, data
      person = Gabb::Person.find(payload["id"])
      person.chats.create! data
    end

  end
end
