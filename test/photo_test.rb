# encoding: utf-8
require 'test_helper'

Flickrie::Photo.instance_eval do
  def public_new(*args)
    new(*args)
  end
end

class PhotoTest < Test::Unit::TestCase
  def setup
    @photo_id = 6946979188
    @set_id = 72157629851991663
    @user_nsid = '67131352@N04'

    # license,date_upload,date_taken,owner_name,icon_server,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_q,url_t,url_s,url_n,url_m,url_z,url_c,url_l,url_o
    @all_extras = %w[license date_upload date_taken owner_name
      icon_server original_format last_update geo tags machine_tags
      o_dims views media path_alias
      url_sq url_q url_t url_s url_n url_m url_z url_c url_l url_o]
  end

  def test_photos_from_set
    VCR.use_cassette 'photo/from_set' do
      photo = Flickrie.photos_from_set(@set_id, :extras => @all_extras).
        find { |photo| photo.id.to_i == @photo_id }

      assert_sizes(photo)
    end
  end

  def test_public_photos_from_user
    VCR.use_cassette 'photo/from_user' do
      photo = Flickrie.public_photos_from_user(@user_nsid, :extras => @all_extras).
        find { |photo| photo.id.to_i == @photo_id }

      assert_sizes(photo, :exclude => ['Square 150', 'Small 320', 'Medium 800'])
    end
  end

  def test_get_photo_sizes
    VCR.use_cassette 'photo/get_sizes' do
      [Flickrie.get_photo_sizes(@photo_id),
       Flickrie::Photo.public_new('id' => @photo_id.to_s).get_sizes].
        each do |photo|
          assert_equal true, photo.can_download?
          assert_equal true, photo.can_blog?
          assert_equal true, photo.can_print?

          assert_sizes(photo)
        end
    end
  end

  def test_search_photos
    VCR.use_cassette 'photo/search' do
      photo = Flickrie.search_photos(:user_id => @user_nsid, :extras => @all_extras).
        find { |photo| photo.id.to_i == @photo_id }

      assert_sizes(photo)
    end
  end

  def assert_sizes(photo, options = {})
    options[:exclude] ||= []
    [
      [[photo.square(75), photo.square75],   ['Square 75', '75x75']],
      [[photo.thumbnail],                    ['Thumbnail', '75x100']],
      [[photo.square(150), photo.square150], ['Square 150', '150x150']],
      [[photo.small(240), photo.small240],   ['Small 240', '180x240']],
      [[photo.small(320), photo.small320],   ['Small 320', '240x320']],
      [[photo.medium(500), photo.medium500], ['Medium 500', '375x500']],
      [[photo.medium(640), photo.medium640], ['Medium 640', '480x640']],
      [[photo.medium(800), photo.medium800], ['Medium 800', '600x800']],
      [[photo.large(1024), photo.large1024], ['Large 1024', '768x1024']]
    ].
      reject { |_, expected_values| options[:exclude].include?(expected_values.first) }.
      each do |photos, expected_values|
        flickr_size, size = expected_values
        photos.each do |photo|
          assert_equal flickr_size, photo.size
          assert_equal size, "#{photo.width}x#{photo.height}", "Non bang versions"
          refute photo.source_url.empty?
        end
      end

    [
      [[proc { photo.square!(75) }, proc { photo.square75! }],   ['Square 75', '75x75']],
      [[proc { photo.thumbnail! }],                              ['Thumbnail', '75x100']],
      [[proc { photo.square!(150) }, proc { photo.square150! }], ['Square 150', '150x150']],
      [[proc { photo.small!(240) }, proc { photo.small240! }],   ['Small 240', '180x240']],
      [[proc { photo.small!(320) }, proc { photo.small320! }],   ['Small 320', '240x320']],
      [[proc { photo.medium!(500) }, proc { photo.medium500! }], ['Medium 500', '375x500']],
      [[proc { photo.medium!(640) }, proc { photo.medium640! }], ['Medium 640', '480x640']],
      [[proc { photo.medium!(800) }, proc { photo.medium800! }], ['Medium 800', '600x800']],
      [[proc { photo.large!(1024) }, proc { photo.large1024! }], ['Large 1024', '768x1024']]
    ].
      reject { |_, expected_values| options[:exclude].include?(expected_values.first) }.
      each do |proks, expected_values|
        flickr_size, size = expected_values
        proks.each do |prok|
          prok.call
          assert_equal flickr_size, photo.size
          assert_equal size, "#{photo.width}x#{photo.height}", "Bang versions"
          refute photo.source_url.empty?
        end
      end
  end

  def test_methods_returning_nil
    photo = Flickrie::Photo.new

    assert_nil photo.width
    assert_nil photo.height
    assert_nil photo.source_url
    assert_nil photo.rotation
    assert_equal [], photo.available_sizes
    assert_equal nil, photo.size

    [
      photo.square(75), photo.square(150), photo.thumbnail,
      photo.small(240), photo.small(320), photo.medium(500),
      photo.medium(640), photo.medium(800), photo.large(1024),
      photo.original, photo.square75, photo.square150,
      photo.small240, photo.small320, photo.medium500,
      photo.medium640, photo.medium800, photo.large1024,
      photo.largest
    ].
      each do |photo|
        assert_nil photo.source_url
        assert_nil photo.width
        assert_nil photo.height
      end

    [
      proc { photo.square!(75) }, proc { photo.square!(150) },
      proc { photo.thumbnail! }, proc { photo.small!(240) },
      proc { photo.small!(320) }, proc { photo.medium!(500) },
      proc { photo.medium!(640) }, proc { photo.medium!(800) },
      proc { photo.large!(1024) }, proc { photo.original! },
      proc { photo.square75! }, proc { photo.square150! },
      proc { photo.small240! }, proc { photo.small320! },
      proc { photo.medium500! }, proc { photo.medium640! },
      proc { photo.medium800! }, proc { photo.large1024! },
      proc { photo.largest! }
    ].
      each do |prok|
        prok.call
        assert_nil photo.source_url
        assert_nil photo.width
        assert_nil photo.height
      end
  end

  def test_photo_upload
    VCR.use_cassette 'photo/upload' do
      photo_path = File.join(File.expand_path(File.dirname(__FILE__)), 'photo.jpg')
      photo_id = Flickrie.upload(photo_path)
      assert_nothing_raised(Flickrie::Error) { Flickrie.get_photo_info(photo_id) }
      Flickrie.delete_photo(photo_id)
    end
  end

  def test_asynchronous_photo_upload
    VCR.use_cassette 'photo/asynchronous_upload' do
      photo_path = File.join(File.expand_path(File.dirname(__FILE__)), 'photo.jpg')
      ticket_id = Flickrie.upload(photo_path, :async => 1)
      begin
        ticket = Flickrie.check_upload_tickets([ticket_id]).first
      end until ticket.complete?
      photo_id = ticket.photo_id
      assert_nothing_raised(Flickrie::Error) { Flickrie.get_photo_info(photo_id) }
      Flickrie.delete_photo(photo_id)
    end
  end

  def test_get_photo_exif
    VCR.use_cassette 'photo/get_exif' do
      [Flickrie.get_photo_exif(@photo_id),
       Flickrie::Photo.public_new('id' => @photo_id).get_exif].
        each do |photo|
          assert_equal "Canon PowerShot G12", photo.camera
          assert_equal "180 dpi", photo.exif.get('X-Resolution')
          assert_equal "180 dpi", photo.exif.get('X-Resolution', :data => 'clean')
          assert_equal "180",     photo.exif.get('X-Resolution', :data => 'raw')
        end
    end
  end

  def test_other_api_calls
    VCR.use_cassette 'photo/other_api_calls' do
      # add_photo_tags, get_photo_info, remove_photo_tag,
      # search_photos, photos_from_contacts

      assert_nothing_raised do
        Flickrie.add_photo_tags(@photo_id, "janko")
        photo = Flickrie.get_photo_info(@photo_id)
        tag = photo.tags.find { |tag| tag.content == "janko" }
        Flickrie.remove_photo_tag(tag.id)
        Flickrie.photos_from_contacts(:include_self => 1)
        Flickrie.public_photos_from_user_contacts(@user_nsid, :include_self => 1)
        Flickrie.get_photo_context(@photo_id)
        Flickrie.search_photos(:user_id => @user_nsid)
      end
    end
  end
end
