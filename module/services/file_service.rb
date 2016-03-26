module SkeletonApp

	class FileService

    def self.decode_string_to_file base64_string, key
      file = File.open("tmp/#{key}", 'wb')
      file.write(Base64.decode64(base64_string))
      file.close
      file
    end

    def self.upload_file data
      file = File.open(self.decode_string_to_file data["file"], data["filename"])
      uid = Dragonfly.app.store(file.read, 'name' => data["filename"])
      file.close
      File.delete(file)
      uid
    end

		def self.fetch_image image_uid, params = Hash.new
			if params["thumb"]
				Dragonfly.app.fetch(image_uid).thumb(params["thumb"])
			else
				Dragonfly.app.fetch(image_uid)
			end
		end

		def self.get_bucket
			s3 = Aws::S3::Resource.new
			s3.bucket(ENV['SKELETON_APP_AWS_BUCKET'])
		end

		def self.get_presigned_url key
			presigner = Aws::S3::Presigner.new
			presigner.presigned_url(:get_object, bucket: ENV['SKELETON_APP_AWS_BUCKET'], key: key, expires_in: 60)
		end

		def self.encode_file filename
			file = File.open(filename)
			string = Base64.encode64(file.read)
			file.close
			string
		end

		def self.image_content_type filename
			extension = filename.split('.').pop
			"image/#{extension}"
		end

	end

end
