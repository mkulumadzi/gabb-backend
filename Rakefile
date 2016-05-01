require 'rake/testtask'
require 'bundler/setup'
require 'mongoid'

require_relative 'module/gabb'

Rake::TestTask.new do |t|
  t.test_files = FileList['spec/lib/gabb/*_spec.rb']
  t.verbose = false
end

Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])

task :default => :test

namespace :db do

  task :create_indexes do
  	Gabb::Person.create_indexes
    Gabb::Token.create_indexes
    Gabb::Session.create_indexes
    Gabb::Chat.create_indexes
  end

  task :remove_indexes do
    Gabb::Person.remove_indexes
    Gabb::Token.remove_indexes
    Gabb::Session.remove_indexes
    Gabb::Chat.create_indexes
  end

  task :reset do
    Gabb::Person.delete_all
    Gabb::Token.delete_all
    Gabb::Session.delete_all
    Gabb::Chat.delete_all
  end

  task :seed do
    Gabb::Person.delete_all
    Gabb::Token.delete_all
    Gabb::Session.delete_all
    Gabb::Chat.delete_all

    Gabb::Person.create!(username: "evan.waters@gmail.com", device_token: "dbeb8d8e3ecb759e38573641b7494731423aa53aa3583ca2ba1920613cf0964f")
  end

end

namespace :auth do

  task :admin_token do
    puts Gabb::AuthService.get_admin_token
  end

  task :app_token do
    puts Gabb::AuthService.get_app_token
  end

  task :mark_token_as_invalid, [:token] do |t, args|
  	token = Gabb::Token.find_or_create_by(value: args[:token])
  	token.mark_as_invalid
  end

  task :mark_token_as_valid, [:token] do |t, args|
  	token = Gabb::Token.find_or_create_by(value: args[:token])
  	token.mark_as_valid
  end

end

namespace :notifications do

  task :test do
    puts "Sending test notification for #{ENV['RACK_ENV']} environment"
    person = Gabb::Person.where(username: "evan.waters@gmail.com").first
    n = APNS::Notification.new(person.device_token, alert: "Testing Gabb notifications", badge: nil, other: {type: "Test"})
    puts "Sending notification: #{n}"
    APNS.send_notifications [n]
  end

end
