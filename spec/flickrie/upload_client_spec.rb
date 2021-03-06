require 'spec_helper'

describe Flickrie::UploadClient do
  context "content type" do
    it "should pass the content type", :vcr do
      photo_path = File.expand_path("../../files/photo.bla", __FILE__)
      photo_id = Flickrie.upload(photo_path, :content_type => "image/jpeg")
      Flickrie.photos_from_user(USER_NSID).map(&:id).should include(photo_id)
      Flickrie.delete_photo(photo_id)
    end

    it "should raise an error on unknown content type", :vcr do
      photo_path = File.expand_path("../../files/photo.bla", __FILE__)
      expect { Flickrie.upload(photo_path) }.to raise_error(Flickrie::Error)
    end
  end

  context "invalid credentials" do
    it "should raise errors", :vcr do
      Flickrie.api_key = nil
      Flickrie.shared_secret = nil
      Flickrie.access_token = nil
      Flickrie.access_secret = nil

      expect { Flickrie.upload(PHOTO_PATH) }.to raise_error(Flickrie::Error)

      Flickrie.api_key = ENV['FLICKR_API_KEY']
      expect { Flickrie.upload(PHOTO_PATH) }.to raise_error(Flickrie::Error)

      Flickrie.shared_secret = ENV['FLICKR_SHARED_SECRET']
      expect { Flickrie.upload(PHOTO_PATH) }.to raise_error(Flickrie::Error)

      Flickrie.access_token = ENV['FLICKR_ACCESS_TOKEN']
      expect { Flickrie.upload(PHOTO_PATH) }.to raise_error(Flickrie::Error)

      Flickrie.access_secret = ENV['FLICKR_ACCESS_SECRET']
      expect { Flickrie.upload(PHOTO_PATH) }.to_not raise_error
    end
  end
end
