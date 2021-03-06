require 'date'

module Flickrie
  class User
    def id()           @info['id']          end
    def nsid()         @info['nsid']        end
    def username()     @info['username']    end
    def real_name()    @info['realname']    end
    def location()     @info['location']    end
    def description()  @info['description'] end
    def path_alias()   @info['path_alias']  end
    def icon_server()  @info['iconserver']  end
    def icon_farm()    @info['iconfarm']    end

    def buddy_icon_url
      if icon_farm
        if icon_server.to_i > 0 && (nsid || id)
          "http://farm{#{icon_farm}}.staticflickr.com/{#{icon_server}}/buddyicons/#{nsid || id}.jpg"
        else
          "http://www.flickr.com/images/buddyicon.jpg"
        end
      end
    end

    # ==== Example
    #
    #   user.time_zone.offset # => "+01:00"
    #   user.time_zone.label  # => "Sarajevo, Skopje, Warsaw, Zagreb"
    def time_zone() Struct.new(:label, :offset).new(*@info['timezone'].values) rescue nil end

    def photos_url()  @info['photosurl']  || "http://www.flickr.com/photos/#{nsid || id}" end
    def profile_url() @info['profileurl'] || "http://www.flickr.com/people/#{nsid || id}" end
    def mobile_url()  @info['mobileurl'] end

    def first_taken() DateTime.parse(@info['photos']['firstdatetaken']).to_time rescue nil end
    def first_uploaded() Time.at(Integer(@info['photos']['firstdate'])) rescue nil end

    def favorited_at() Time.at(Integer(@info['favedate'])) rescue nil end

    def media_count() Integer(@info['photos']['count']) rescue nil end
    alias photos_count media_count
    alias videos_count media_count

    # The same as calling <tt>Flickrie.public_photos_from_user(user.nsid)</tt>
    def public_photos() Flickrie.public_photos_from_user(nsid || id) end

    def pro?() Integer(@info['ispro']) == 1 rescue nil end

    def [](key) @info[key] end
    def hash() @info end

    # The same as calling <tt>Flickrie.get_user_info(user.nsid)</tt>
    def get_info(params = {}, info = nil)
      info ||= Flickrie.client.get_user_info(nsid || id, params).body['person']
      @info.update(info)

      %w[username realname location description profileurl
         mobileurl photosurl].each do |attribute|
        @info[attribute] = @info[attribute]['_content']
      end
      %w[count firstdatetaken firstdate].each do |photo_attribute|
        @info['photos'][photo_attribute] = @info['photos'][photo_attribute]['_content']
      end

      self
    end

    private

    def initialize(info = {})
      raise ArgumentError if info.nil?

      @info = info
    end

    def self.from_info(info)
      new.get_info({}, info)
    end

    def self.from_find(info)
      info['username'] = info['username']['_content']
      new(info)
    end

    def self.from_test(info)
      from_find(info)
    end
  end
end
