require_relative '../../spec_helper'

describe Gabb::ChatService do

  before do
    @person = create(:person, username: SecureRandom.hex)
    @payload = Hash("id" => @person.id)
    @person2 = create(:person, username: SecureRandom.hex)
  end

  describe 'chats' do

    before do

      3.times do
        @person.chats.create!(Hash(podcast_id: 2))
      end

      2.times do
        @person.chats.create!(Hash(podcast_id: 3))
      end

      2.times do
        @person2.chats.create!(Hash(podcast_id: 2))
      end

    end

    it 'must return an array of chats' do
      chats = Gabb::ChatService.chats @payload, nil
      chats.must_be_instance_of Array
      chats[0].must_be_instance_of Gabb::Chat
      chats.count.must_equal Gabb::Chat.count
    end

    it 'must filter the chats if parameters are given' do
      chats = Gabb::ChatService.chats @payload, Hash(podcast_id: 2)
      chats.count.must_equal Gabb::Chat.where(podcast_id: 2).count
    end

  end

  describe 'create chat' do

    it 'must create the chat' do
      data = Hash(podcast_id: 2, text: "Wow this is fun!")
      count = @person.chats.count
      chat = Gabb::ChatService.create_chat @payload, data
      chat.must_be_instance_of Gabb::Chat
      @person.chats.count.must_equal count + 1
    end

  end

end
