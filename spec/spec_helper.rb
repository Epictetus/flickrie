# encoding: utf-8
require 'flickrie'
require 'vcr'
begin
  require 'debugger'
rescue LoadError
end

module RSpecHelpers
  def test_recursively(object, attribute, hash = nil)
    expectation = hash || @attributes[attribute]
    unless expectation.is_a?(Hash)
      object.send(attribute).should eq(expectation)
    else
      iterate(object.send(attribute), expectation) do |actual, expected|
        actual.should eq(expected)
      end
    end
  end

  def iterate(object, rest, &block)
    rest.each do |key, value|
      if value.is_a?(Hash)
        iterate(object.send(key), value, &block)
      else
        yield [object.send(key), value]
      end
    end
  end

  # SomeModule::AnotherModule::Class => "some_module/another_module/class"
  def to_file_path(constants)
    constants.split("::").collect do |constant|
      constant.split(/(?=[A-Z])/).map(&:downcase).join('_')
    end.join('/')
  end
end

RSpec.configure do |c|
  c.include RSpecHelpers
  c.before(:all) do
    Flickrie.api_key = ENV['FLICKR_API_KEY']
    Flickrie.shared_secret = ENV['FLICKR_SHARED_SECRET']
    Flickrie.access_token = ENV['FLICKR_ACCESS_TOKEN']
    Flickrie.access_secret = ENV['FLICKR_ACCESS_SECRET']
  end
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.around(:each, :vcr) do |example|
    if example.metadata[:cassette].nil?
      # the example is wrapped in a 'context' block
      class_name = example.metadata[:example_group][:example_group][:description_args].first.to_s
      cassette_name = example.metadata[:example_group][:description_args].first
    else
      # the example isn't wrapped in a 'context' block
      class_name = example.metadata[:example_group][:description_args].first.to_s
      cassette_name = example.metadata[:cassette]
    end

    folder = to_file_path(class_name.match(/^Flickrie::/).post_match)
    VCR.use_cassette("#{folder}/#{cassette_name}") { example.call }
  end
  c.fail_fast = true
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :faraday
  c.default_cassette_options = {
    :record => :new_episodes,
    :serialize_with => :syck,
    :match_requests_on => [:method, VCR.request_matchers.uri_without_param(:api_key)]
  }
  c.filter_sensitive_data('API_KEY') { ENV['FLICKR_API_KEY'] }
  c.filter_sensitive_data('ACCESS_TOKEN') { ENV['FLICKR_ACCESS_TOKEN'] }
end

PHOTO_PATH = File.expand_path('../files/photo.jpg', __FILE__).freeze
PHOTO_ID = '6946979188'.freeze
VIDEO_ID = '7093038981'.freeze
SET_ID = '72157629851991663'.freeze
USER_NSID = '67131352@N04'.freeze
USER_USERNAME = 'Janko Marohnić'.freeze
EXTRAS = %w[license date_upload date_taken owner_name
  icon_server original_format last_update geo tags machine_tags
  o_dims views media path_alias url_sq url_q url_t url_s url_n
  url_m url_z url_c url_l url_o].join(',').freeze
# for copying:
#   license,date_upload,date_taken,owner_name,icon_server,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_q,url_t,url_s,url_n,url_m,url_z,url_c,url_l,url_o

klasses = [Flickrie::Set, Flickrie::Photo, Flickrie::Video, Flickrie::User, Flickrie::Location]
klasses.each do |klass|
  klass.instance_eval do
    def public_new(*args)
      new(*args)
    end
  end
end

class Hash
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  def except(*keys)
    self.dup.except!(*keys)
  end
end
