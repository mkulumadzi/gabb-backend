module SkeletonApp

  class AppService
    # Convenience Methods
    def self.add_if_modified_since_to_request_parameters app
      if app.request.env["HTTP_IF_MODIFIED_SINCE"]
        utc_date = Time.parse(app.request.env["HTTP_IF_MODIFIED_SINCE"])
        app.params[:updated_at] = { "$gt" => utc_date }
      end
    end

    def self.add_if_modified_since_to_request_as_date app
      if app.request.env["HTTP_IF_MODIFIED_SINCE"]
        utc_date = Time.parse(app.request.env["HTTP_IF_MODIFIED_SINCE"])
        app.params[:updated_at] = utc_date
      end
    end

    def self.get_token_from_authorization_header request
      token_header = request.env["HTTP_AUTHORIZATION"]
      if token_header
        token_header.split(' ')[1]
      else
        nil
      end
    end

    def self.get_payload_from_authorization_header request
      if request.env["HTTP_AUTHORIZATION"] != nil
        begin
          token = self.get_token_from_authorization_header request
          decoded_token = SkeletonApp::AuthService.decode_token token
          payload = decoded_token[0]
        rescue JWT::ExpiredSignature
          "Token expired"
        rescue JWT::VerificationError
          "Invalid token signature"
        rescue JWT::DecodeError
          "Token is invalid"
        end
      else
        "No token provided"
      end
    end

    def self.unauthorized? request, required_scope
      payload = self.get_payload_from_authorization_header request
      token = self.get_token_from_authorization_header request
      if SkeletonApp::AuthService.token_is_invalid(token)
        true
      elsif payload["scope"] == nil
        true
      elsif payload["scope"].include? required_scope
        false
      else
        true
      end
    end

    def self.not_authorized_owner? request, required_scope, person_id
      payload = self.get_payload_from_authorization_header request
      id = payload["id"]
      token = self.get_token_from_authorization_header request

      if SkeletonApp::AuthService.token_is_invalid(token)
        true
      elsif payload["scope"] == nil
        true
      elsif payload["scope"].include?(required_scope) && id == person_id
        false
      else
        true
      end
    end

    def self.not_admin_or_owner? request, scope, person_id
      if self.unauthorized?(request, "admin") && self.not_authorized_owner?(request, scope, person_id)
        true
      else
        false
      end
    end

    def self.get_api_version_from_content_type request
      content_type = request.env["CONTENT_TYPE"]
      if content_type && content_type.include?("application/vnd.SkeletonApp")
        version = content_type.split('.').last.split('+')[0]
      else
        version = "v1"
      end
      version
    end

    def self.add_updated_since_to_query query, params
      if params[:updated_at] then query = query.where(updated_at: params[:updated_at]) end
      query
    end

    def self.convert_objects_to_documents array
      document_array = []
      array.each { |e| document_array << e.as_document }
      document_array
    end

    # Configuring a global variable that checks whether sending email is enabled in the app
    def self.email_enabled?
      ENV['SKELETON_APP_EMAIL_ENABLED'] == 'yes' ? true : false
    end

    def self.email_api_key request
      if request.params["test"] == "true"
        "POSTMARK_API_TEST"
      else
        ENV["POSTMARK_API_KEY"]
      end
    end

    def self.send_authorization_email_if_enabled person, request
      if self.email_enabled?
        api_key = SkeletonApp::AppService.email_api_key request
        SkeletonApp::AuthService.send_email_validation_email_if_necessary person, api_key
      end
    end

    def self.send_validation_email_for_email_change_if_enabled person, request, old_email
      if self.email_enabled? && old_email && person.email != old_email
        person.email_address_validated = false
        person.save
        api_key = SkeletonApp::AppService.email_api_key request
        SkeletonApp::AuthService.send_email_validation_email_if_necessary person, api_key
      end
    end

    def self.send_password_reset_email_if_enabled person, request
      if self.email_enabled?
        api_key = SkeletonApp::AppService.email_api_key request
        SkeletonApp::AuthService.send_password_reset_email person, api_key
      else
        # App expects a hash, so return an empty hash
        Hash.new
      end
    end

    #To Do: Refactor the app so as not to need this method, or the one above
    def self.json_document_for_people_documents people_documents
      people_documents.to_json( :except => ["salt", "hashed_password", "device_token", "facebook_id", "facebook_token"] )
    end

  end

end
