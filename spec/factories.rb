FactoryGirl.define do

  factory :person, class: Gabb::Person do
    username "testuser"
    given_name "Test"
    family_name "User"
    email "testuser@test.com"
    email_address_validated false
    phone "5554443333"
    hashed_password "hash"
    salt "salt"
  end

  factory :session, class: Gabb::Session do
    title "This American Life"
    episode_url "http://example.podcast.com/episode/2"
    episode_hash "abcdef"
    start_time_scale 1000000
    start_time_value 0
    stop_time_scale 1000000
    stop_time_value 351815115
  end

  factory :chat, class: Gabb::Chat do
    podcast_id 2
    text "This is a chat"
  end

end
