require 'spec_helper'

describe Flickrie::User do
  before(:all) do
    @attributes = {
      :id => USER_NSID,
      :nsid => USER_NSID,
      :username => USER_USERNAME,
      :real_name => USER_USERNAME,
      :location => "Zagreb, Croatia",
      :time_zone => {
        :label => "Sarajevo, Skopje, Warsaw, Zagreb",
        :offset => "+01:00"
      },
      :description => "I'm a programmer, and I'm gonna program a badass Ruby library for Flickr.",
      :icon_server => "5464",
      :icon_farm => 6,
      :pro? => false,
      :media_count => 98
    }
  end

  context "get info" do
    it "should have all attributes correctly set", :vcr do
      [
        Flickrie.get_user_info(USER_NSID),
        Flickrie::User.public_new('nsid' => USER_NSID).get_info
      ].
        each do |user|
          @attributes.keys.each do |attribute|
            test_recursively(user, attribute)
          end

          [:profile_url, :mobile_url, :photos_url, :buddy_icon_url].each do |attribute|
            user.send(attribute).should_not be_empty
          end

          [:first_taken, :first_uploaded].each do |time_attribute|
            user.send(time_attribute).should be_an_instance_of(Time)
          end
        end
    end
  end

  context "find by username or email" do
    it "should have all attributes correctly set", :vcr do
      [
        Flickrie.find_user_by_username(USER_USERNAME),
        Flickrie.find_user_by_email('janko.marohnic@gmail.com')
      ].
        each do |user|
          [:id, :nsid, :username].each do |attribute|
            test_recursively(user, attribute)
          end
        end
    end
  end
end
