require 'rake/testtask'
require 'bundler/setup'
require 'mongoid'

require_relative 'module/skeleton_app'

Rake::TestTask.new do |t|
  t.test_files = FileList['spec/lib/skeleton_app/*_spec.rb']
  t.verbose = false
end

Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])

task :default => :test

namespace :db do

  task :create_indexes do
  	SkeletonApp::Person.create_indexes
    SkeletonApp::Token.create_indexes
  end

  task :remove_indexes do
    SkeletonApp::Person.remove_indexes
    SkeletonApp::Token.remove_indexes
  end

  task :reset do
    SkeletonApp::Person.delete_all
    SkeletonApp::Token.delete_all
  end

end

namespace :auth do

  task :admin_token do
    puts SkeletonApp::AuthService.get_admin_token
  end

  task :app_token do
    puts SkeletonApp::AuthService.get_app_token
  end

  task :mark_token_as_invalid, [:token] do |t, args|
  	token = SkeletonApp::Token.find_or_create_by(value: args[:token])
  	token.mark_as_invalid
  end

  task :mark_token_as_valid, [:token] do |t, args|
  	token = SkeletonApp::Token.find_or_create_by(value: args[:token])
  	token.mark_as_valid
  end

  task :download_certificates do
    get_certificate_file_from_aws_if_neccessary 'private.pem', 'certificates'
    get_certificate_file_from_aws_if_neccessary 'public.pem', 'certificates'
  end

end
