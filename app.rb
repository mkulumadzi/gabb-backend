require_relative 'module/skeleton_app'

get '/' do
  "Hello World!"
end

options "*" do
  response.headers["Allow"] = "GET,POST,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization, Access-Control-Allow-Credentials"
  response.headers["Access-Control-Allow-Origin"] = "*"
end

# Create a new person
# Scope: create-person
post '/person/new' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "create-person") then return [401, nil] end

  begin
    data = JSON.parse request.body.read
    person = SkeletonApp::PersonService.create_person data
    SkeletonApp::AppService.send_authorization_email_if_enabled person, request
    headers = { "location" => person.uri }
    [201, headers, nil]
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongo::Error::OperationFailure => error
    response_body = Hash["message", "An account with that username already exists!"].to_json
    [403, nil, response_body]
  rescue RuntimeError => error
    status = 403
    response_body = Hash["message", error.to_s].to_json
    [403, nil, response_body]
  end
end

# Check if a registration field such as username is available
# Scope: create-person
get '/available' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "create-person") then return [401, nil] end
  begin
    response_body = SkeletonApp::PersonService.check_field_availability(params).to_json
    [200, response_body]
  rescue RuntimeError
    [404, nil]
  end
end

# Login and return an oauth token if successful
# Scope: nil
post '/login' do
  content_type :json
  begin
    data = JSON.parse request.body.read
    person = SkeletonApp::LoginService.check_login data
    if person
      response_body = SkeletonApp::LoginService.response_for_successful_login person
      [200, response_body]
    else
      [401, nil]
    end
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    [401, nil]
  end
end

# Retrieve a single person record
# Scope: can-read
get '/person/id/:id' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "can-read") then return [401, nil] end

  begin
    person = SkeletonApp::Person.find(params[:id])
    if request.env["HTTP_IF_MODIFIED_SINCE"] == nil
      [200, person.as_json]
    else
      modified_since = Time.parse(env["HTTP_IF_MODIFIED_SINCE"])
      if person.updated_at.to_i > modified_since.to_i
        [200, person.as_json]
      else
        [304, nil]
      end
    end
  rescue Mongoid::Errors::DocumentNotFound
    [404, nil]
  end

end

# Update a person record
# Scope: admin or (can_write & is person)
post '/person/id/:id' do
  content_type :json
  if SkeletonApp::AppService.not_admin_or_owner?(request, "can-write", params[:id]) then return [401, nil] end
  begin
    data = JSON.parse request.body.read
    person = SkeletonApp::Person.find(params[:id])
    SkeletonApp::PersonService.update_person person, data
    SkeletonApp::AppService.send_validation_email_for_email_change_if_enabled person, request, data["email"]
    [204, nil]
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    [404, nil]
  rescue Mongo::Error::OperationFailure
    [403, nil]
  rescue ArgumentError
    [403, nil]
  rescue RuntimeError => error
    status = 403
    response_body = Hash["message", error.to_s].to_json
    [403, nil, response_body]
  end
end

# Reset a password for a user
# Scope: reset-password
post '/person/id/:id/reset_password' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "reset-password") then return [401, nil] end
  begin
    data = JSON.parse(request.body.read)
    SkeletonApp::LoginService.password_reset_by_user params[:id], data
    [204, nil]
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    [404, nil]
  rescue RuntimeError => error
    response_body = Hash["message", error.to_s].to_json
    [403, response_body]
  end

end

# Validate email using a temporary token, via a webapp
post '/validate_email' do
  content_type :json
  response.headers["Access-Control-Allow-Origin"] = "*"

  # Check the token
  if SkeletonApp::AppService.unauthorized?(request, "validate-email") then return [401, nil] end

  token = SkeletonApp::AppService.get_token_from_authorization_header request
  if SkeletonApp::AuthService.token_is_invalid(token) then return [401, nil] end

  payload =  SkeletonApp::AppService.get_payload_from_authorization_header request
  person = SkeletonApp::Person.find(payload["id"])

  person.mark_email_as_valid

  db_token = SkeletonApp::Token.new(value: token)
  db_token.mark_as_invalid

  [204, nil]

end

# Reset password using a temporary token, via a webapp
post '/reset_password' do
  content_type :json
  data = JSON.parse(request.body.read)
  response.headers["Access-Control-Allow-Origin"] = "*"

  # Check the token
  if SkeletonApp::AppService.unauthorized?(request, "reset-password") then return [401, nil] end

  token = SkeletonApp::AppService.get_token_from_authorization_header request
  if SkeletonApp::AuthService.token_is_invalid(token) then return [401, nil] end

  if data["password"] == nil then return [403, nil] end

  payload = SkeletonApp::AppService.get_payload_from_authorization_header request
  person = SkeletonApp::Person.find(payload["id"])
  SkeletonApp::LoginService.reset_password person, data["password"]

  db_token = SkeletonApp::Token.new(value: token)
  db_token.mark_as_invalid

  [204, nil]

end

#Request token for resetting user password
post '/request_password_reset' do
  content_type :json
  # Check the token
  if SkeletonApp::AppService.unauthorized?(request, "reset-password") then return [401, nil] end

  begin
    data = JSON.parse(request.body.read)
    person = SkeletonApp::Person.find_by(email: data["email"])
    email_sent = SkeletonApp::AppService.send_password_reset_email_if_enabled person, request
    if email_sent[:error_code] == 0
      [201, nil]
    else
      [403, nil]
    end
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    response_body = Hash["message", "An account with that email does not exist."].to_json
    [404, response_body]
  rescue Postmark::InvalidMessageError
    response_body = Hash["message", "Email address has been marked as inactive."].to_json
    [403, response_body]
  end

end

# View records for all people in the database.
# Filtering implemented, for example: /people?username=bigedubs
# Scope: admin
get '/people' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "admin") then return [401, nil] end
  SkeletonApp::AppService.add_if_modified_since_to_request_parameters self
  people_docs = SkeletonApp::PersonService.get_people(params)
  response_body = SkeletonApp::AppService.json_document_for_people_documents people_docs
  [200, response_body]

end

# Search people by username or name
# Scope: can-read
get '/people/search' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "can-read") then return [401, nil] end

  begin
    people_returned = SkeletonApp::PersonService.search_people params
    people_docs = []
    people_returned.each do |person|
      people_docs << person.as_document
    end
    response_body = SkeletonApp::AppService.json_document_for_people_documents people_docs
    [200, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    [404, response_body]
  end

end

post '/people/find_matches' do
  content_type :json
  if SkeletonApp::AppService.unauthorized?(request, "can-read") then return [401, nil] end
  begin
    data = JSON.parse request.body.read
    people = SkeletonApp::PersonService.find_people_from_list_of_emails data["emails"]
    documents = SkeletonApp::AppService.convert_objects_to_documents people
    response_body = SkeletonApp::AppService.json_document_for_people_documents documents
    [201, response_body]
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue Mongoid::Errors::DocumentNotFound
    [404, nil]
  end
end

# Upload a File
# Scope: can-write
post '/upload' do
  if SkeletonApp::AppService.unauthorized?(request, "can-write") then return [401, nil] end

  begin
    data = JSON.parse request.body.read.gsub("\n", "")
    uid = SkeletonApp::FileService.upload_file data
    headers = { "location" => uid }
    [201, headers, nil]
  rescue JSON::ParserError
    response_body = Hash["message", "Malformed JSON"].to_json
    [400, nil, response_body]
  rescue ArgumentError => error
    response_body = Hash["message", error.to_s].to_json
    [403, nil, response_body]
  rescue RuntimeError => error
    response_body = Hash["message", error.to_s].to_json
    [403, nil, response_body]
  end

end

# Get a specific image
# Scope: can-read
get '/image/*' do
  uid = params['splat'][0]
  if SkeletonApp::AppService.unauthorized?(request, "can-read") then return [401, nil] end
  redirect SkeletonApp::FileService.get_presigned_url uid
end
