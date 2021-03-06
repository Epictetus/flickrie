require 'faraday_middleware'

module Flickrie
  OPEN_TIMEOUT = 4
  TIMEOUT = 6

  class << self
    def self.attr_accessor_with_client_reset(*attributes) # :nodoc:
      attr_reader *attributes

      attributes.each do |attribute|
        define_method "#{attribute}=" do |value|
          instance_variable_set "@#{attribute}", value
          @client = @upload_client = nil
        end
      end
    end

    attr_accessor_with_client_reset :api_key, :shared_secret,
      :timeout, :open_timeout, :access_token, :access_secret

    # ==== Example
    #
    #   Flickrie.client.get  "flickr.photos.licenses.getInfo"
    #   Flickrie.client.post "flickr.photos.licenses.setLicense", :photo_id => 1241497, :license_id => 2
    def client
      @client ||= new_client
    end

    def new_client(access_token_hash = {}) # :nodoc:
      Client.new(params) do |b|
        b.use Middleware::Retry
        b.use FaradayMiddleware::OAuth,
          :consumer_key => api_key,
          :consumer_secret => shared_secret,
          :token => access_token_hash[:token] || access_token,
          :token_secret => access_token_hash[:secret] || access_secret

        b.use Middleware::StatusCheck
        b.use FaradayMiddleware::ParseJson
        b.use Middleware::OAuthCheck

        b.adapter :net_http
      end
    end

    private

    def params
      {
        :url => 'http://api.flickr.com/services/rest',
        :params => {
          :format => 'json',
          :nojsoncallback => '1',
          :api_key => api_key
        },
        :request => {
          :open_timeout => open_timeout || OPEN_TIMEOUT,
          :timeout => timeout || TIMEOUT
        }
      }
    end
  end

  class Client < Faraday::Connection # :nodoc:
    def get(method, params = {})
      super() do |req|
        req.params[:method] = method
        req.params.update(params)
      end
    end

    def post(method, params = {})
      super() do |req|
        req.params[:method] = method
        req.params.update(params)
      end
    end

    #--
    # people
    def find_user_by_email(email, params = {})
      get 'flickr.people.findByEmail',
        {:find_email => email}.merge(params)
    end

    def find_user_by_username(username, params = {})
      get 'flickr.people.findByUsername',
        {:username => username}.merge(params)
    end

    def get_user_info(user_nsid, params = {})
      get 'flickr.people.getInfo',
        {:user_id => user_nsid}.merge(params)
    end

    def media_from_user(user_nsid, params = {})
      get 'flickr.people.getPhotos',
        ensure_media({:user_id => user_nsid}.merge(params))
    end

    def public_media_from_user(user_nsid, params = {})
      get 'flickr.people.getPublicPhotos',
        ensure_media({:user_id => user_nsid}.merge(params))
    end

    #--
    # photos
    def add_media_tags(media_id, tags, params = {})
      post 'flickr.photos.addTags',
        {:photo_id => media_id, :tags => tags}.merge(params)
    end

    def delete_media(media_id, params = {})
      post 'flickr.photos.delete',
        {:photo_id => media_id}.merge(params)
    end

    def media_from_contacts(params = {})
      get 'flickr.photos.getContactsPhotos', ensure_media(params)
    end

    def public_media_from_user_contacts(user_nsid, params = {})
      get 'flickr.photos.getContactsPublicPhotos',
        ensure_media({:user_id => user_nsid}.merge(params))
    end

    def get_media_context(media_id, params = {})
      get 'flickr.photos.getContext',
        {:photo_id => media_id}.merge(params)
    end

    def get_media_counts(params = {})
      get 'flickr.photos.getCounts', params
    end

    def get_media_exif(media_id, params = {})
      get 'flickr.photos.getExif',
        {:photo_id => media_id}.merge(params)
    end

    def get_media_favorites(media_id, params = {})
      get 'flickr.photos.getFavorites',
        {:photo_id => media_id}.merge(params)
    end

    def get_media_info(media_id, params = {})
      get 'flickr.photos.getInfo',
        {:photo_id => media_id}.merge(params)
    end

    def get_media_sizes(media_id, params = {})
      get 'flickr.photos.getSizes',
        {:photo_id => media_id}.merge(params)
    end

    def remove_media_tag(tag_id, params = {})
      post 'flickr.photos.removeTag',
        {:tag_id => tag_id}.merge(params)
    end

    def search_media(params = {})
      get 'flickr.photos.search', ensure_media(params)
    end

    #--
    # photos.upload
    def check_upload_tickets(tickets, params = {})
      get 'flickr.photos.upload.checkTickets',
        {:tickets => tickets}.merge(params)
    end

    #--
    # photos.licenses
    def get_licenses(params = {})
      get 'flickr.photos.licenses.getInfo', params
    end

    #--
    # photosets
    def get_set_info(set_id, params = {})
      get 'flickr.photosets.getInfo',
        {:photoset_id => set_id}.merge(params)
    end

    def sets_from_user(user_nsid, params = {})
      get 'flickr.photosets.getList',
        {:user_id => user_nsid}.merge(params)
    end

    def media_from_set(set_id, params = {})
      get 'flickr.photosets.getPhotos',
        ensure_media({:photoset_id => set_id}.merge(params))
    end

    #--
    # test
    def test_login(params = {})
      get 'flickr.test.login', params
    end

    private

    def ensure_media(params)
      params.dup.tap do |dup_params|
        dup_params[:extras] = [dup_params[:extras], 'media'].compact.join(',')
      end
    end
  end
end
