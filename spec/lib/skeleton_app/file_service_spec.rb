require_relative '../../spec_helper'

describe SkeletonApp::FileService do

  describe 'decode a base64 string and return a file' do

    before do
      @string = "This is a string to encode."
      base64_string = Base64.encode64(@string)
      @key = "samplekey"
      @file = File.open(SkeletonApp::FileService.decode_string_to_file base64_string, @key)
      @file_contents = @file.read
    end

    after do
      @file.close
      File.delete(@file)
    end

    it 'must decode the string and store it in the file' do
      @file_contents.must_equal @string
    end

    it 'must store the key as the name of the file' do
      File.basename(@file).must_equal @key
    end

  end

  describe 'upload file using Dragonfly' do

    before do
      @contents = "I am uploading this file."
      base64_string = Base64.encode64(@contents)
      @filename = "sample.txt"
      data = JSON.parse(('{"file": "'+ base64_string + '", "filename": "' + @filename + '"}').gsub("\n", ""))
      @uid = SkeletonApp::FileService.upload_file data
    end

    it 'must return a String as the UID' do
      @uid.must_be_instance_of String
    end

    it 'must upload the file to the AWS S3 store' do
      contents = Dragonfly.app.fetch(@uid).data
      contents.must_equal @contents
    end

    it 'must store the filename' do
      Dragonfly.app.fetch(@uid).name.must_equal @filename
    end

    it 'must delete the temporary file' do
      File.exists?('tmp/' + @filename).must_equal false
    end

  end

  describe 'fetch image' do

    before do
      @image = File.open('spec/resources/image2.jpg')
      @uid = Dragonfly.app.store(@image.read, 'name' => 'image2.jpg')
    end

    after do
      @image.close
    end

    describe 'fetch full image' do

      before do
        params = ""
        @image_fetched = SkeletonApp::FileService.fetch_image @uid, params
      end

      it 'must fetch the image' do
        @image_fetched.name.must_equal 'image2.jpg'
      end

      it 'must fetch the full image' do
        @image_fetched.size.must_equal @image.size
      end

    end

    describe 'fetch image with thumbnail' do

      it 'must resize the image if a thumbnail is given' do
        params = Hash["thumb", "400x"]
        image_fetched = SkeletonApp::FileService.fetch_image @uid, params
        image_fetched.width.must_equal 400
      end

      it 'must return a Argument Error if the thumbnail parameter is invalid' do
        params = Hash["thumb", "splat"]
        assert_raises ArgumentError do
          image_fetched = SkeletonApp::FileService.fetch_image @uid, params
          image_fetched.apply
        end
      end

    end

  end

  describe 'get AWS S3 bucket' do

    it 'must return an S3 bucket instance' do
      SkeletonApp::FileService.get_bucket.must_be_instance_of Aws::S3::Bucket
    end

    it 'must point to the bucket specified in the environment variable' do
      bucket = SkeletonApp::FileService.get_bucket
      bucket.name.must_equal ENV['SKELETON_APP_AWS_BUCKET']
    end

  end


  describe 'get presigned URL from AWS for a key' do

    before do
      @key = 'test/image1.jpg'
      @url = SkeletonApp::FileService.get_presigned_url @key
    end

    it 'must return a presigned url as a String' do
      @url.must_be_instance_of String
    end

    it 'must include the key' do
      assert_operator @url.index(@key), :>, 0
    end

    it 'must expire in 60 seconds' do
      assert_operator @url.index('Expires=60'), :>, 0
    end

  end

  describe 'base 64 encode a file' do

    before do
      @base64String = SkeletonApp::FileService.encode_file 'spec/resources/image1.jpg'
    end

    it 'must return a string' do
      @base64String.must_be_instance_of String
    end

    it 'must be the base 64-encoded version of the file' do
      file = File.open('spec/resources/image1.jpg')
      encoded = Base64.encode64(file.read)
      file.close
      @base64String.must_equal encoded
    end

  end

  describe 'get image content type from filename' do

    it 'must return a string with image/ and the file extension' do
      filename = 'tmp/filename.png'
      SkeletonApp::FileService.image_content_type(filename).must_equal "image/png"
    end

  end

end
