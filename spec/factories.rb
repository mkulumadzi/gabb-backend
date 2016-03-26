FactoryGirl.define do

  factory :person, class: SkeletonApp::Person do
    username "testuser"
    given_name "Test"
    family_name "User"
    email "testuser@test.com"
    email_address_validated false
    phone "5554443333"
    hashed_password "hash"
    salt "salt"
    device_token "abc123"
    facebook_id "123"
    facebook_token "abcdef"
  end

end
