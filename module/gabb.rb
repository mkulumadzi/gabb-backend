# load path
lib_path = File.expand_path('../', __FILE__)
($:.unshift lib_path) unless ($:.include? lib_path)

Bundler.require(:default)

# load path
lib_path = File.expand_path('../', __FILE__)
($:.unshift lib_path) unless ($:.include? lib_path)

Bundler.require(:default)

Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO

Dir[File.dirname(__FILE__) + '/models/*.rb'].each do |file|
	require file
end

Dir[File.dirname(__FILE__) + '/services/*.rb'].each do |file|
	require file
end

## Configuring AWS for storing images
## To Do: Use Dragonfly for storing as well?
Aws.config.update({
  region: 'us-west-2',
  credentials: Aws::Credentials.new(ENV['GABB_AWS_ACCESS_KEY_ID'], ENV['GABB_AWS_SECRET_ACCESS_KEY'])
})

## Configuring Dragonfly for accessing images
Dragonfly.app.configure do
	plugin :imagemagick
	secret 'I miss my Sony camera'

  datastore :s3,
		region: 'us-west-2',
    bucket_name: ENV['GABB_AWS_BUCKET'],
    access_key_id: ENV['GABB_AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['GABB_AWS_SECRET_ACCESS_KEY']
end

## Increasing max keyspace limit to allow photo uploads in base64 format...
if Rack::Utils.respond_to?("key_space_limit=")
  Rack::Utils.key_space_limit = 1048576 # 16 times the default size
end

##Configuring APNS for push notifications
## 2195 is the default port for Apple
APNS.host = 'gateway.sandbox.push.apple.com'

if ENV['RACK_ENV'] == 'staging' || ENV['RACK_ENV'] == 'production'
	APNS.pem  = 'certificates/gabb-push-prod.pem'
	APNS.host = 'gateway.push.apple.com'
else
	APNS.pem  = 'certificates/gabb-push-dev.pem'
	APNS.host = 'gateway.sandbox.push.apple.com'
end

APNS.port = 2195
