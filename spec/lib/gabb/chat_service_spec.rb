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

  describe 'people to notify for chat' do

    before do
      @person.device_token = "foo"
      @person.save
      @person.chats.create!(Hash(podcast_id: 2))

      @person2.chats.create!(Hash(podcast_id: 2))

      @person3 = create(:person, username: SecureRandom.hex, device_token: "abc")
      @person3.chats.create!(Hash(podcast_id: 2))

      @person4 = create(:person, username: SecureRandom.hex, device_token: "abc")
      @person4.chats.create!(Hash(podcast_id: 3))
    end

    it 'must return a query of people who have sent a chat for that podcast and have a device_token, but not the person who sent this chat' do

      chat = @person.chats.create!(Hash(podcast_id: 2))
      people = Gabb::ChatService.people_to_notify_for_chat chat
      people.must_be_instance_of Array
      people[0].must_be_instance_of Gabb::Person

      (people.select { |person| person.id == @person.id}).count.must_equal 0
      (people.select { |person| person.id == @person2.id}).count.must_equal 0
      (people.select { |person| person.id == @person3.id}).count.must_equal 1
      (people.select { |person| person.id == @person4.id}).count.must_equal 0
    end

  end

  describe 'send chat notification' do

    it 'must send the notification without an error' do
      @person.device_token = "foo"
      @person.save
      @person.chats.create!(Hash(podcast_id: 2))

      @person2.device_token = "abc"
      @person2.save
      chat = @person2.chats.create!(Hash(podcast_id: 2))

      Gabb::ChatService.send_chat_notification(chat).must_equal nil

    end

  end

end
