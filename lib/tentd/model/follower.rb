require 'tentd/core_ext/hash/slice'
require 'securerandom'

module TentD
  module Model
    class Follower
      include DataMapper::Resource
      include Permissible
      include RandomPublicId
      include Serializable
      include UserScoped

      storage_names[:default] = 'followers'

      property :id, Serial
      property :groups, Array, :lazy => false, :default => []
      property :entity, Text, :required => true, :lazy => false
      property :public, Boolean, :default => true
      property :profile, Json, :default => {}
      property :licenses, Array, :lazy => false, :default => []
      property :notification_path, Text, :lazy => false, :required => true
      property :mac_key_id, String, :default => lambda { |*args| 's:' + SecureRandom.hex(4) }, :unique => true
      property :mac_key, String, :default => lambda { |*args| SecureRandom.hex(16) }
      property :mac_algorithm, String, :default => 'hmac-sha-256'
      property :mac_timestamp_delta, Integer
      property :created_at, DateTime
      property :updated_at, DateTime
      property :deleted_at, ParanoidDateTime

      has n, :notification_subscriptions, 'TentD::Model::NotificationSubscription', :constraint => :destroy

      # permissions describing who can see them
      has n, :visibility_permissions, 'TentD::Model::Permission', :child_key => [ :follower_visibility_id ], :constraint => :destroy

      # permissions describing what they have access to
      has n, :access_permissions, 'TentD::Model::Permission', :child_key => [ :follower_access_id ], :constraint => :destroy

      def self.create_follower(data, authorized_scopes = [])
        if authorized_scopes.include?(:write_followers) && authorized_scopes.include?(:write_secrets)
          follower = create(data.slice(:public_id, :entity, :groups, :public, :profile, :licenses, :notification_path, :mac_key_id, :mac_key, :mac_algorithm, :mac_timestamp_delta))
          if data.permissions
            follower.assign_permissions(data.permissions, :visibility_permissions)
          end
        else
          follower = create(data.slice('entity', 'licenses', 'profile', 'notification_path'))
        end
        (data.types || ['all']).each do |type_url|
          follower.notification_subscriptions.create(:type => type_url)
        end
        follower
      end

      def self.update_follower(id, data, authorized_scopes = [])
        follower = first(:id => id)
        return unless follower
        whitelist = ['licenses']
        if authorized_scopes.include?(:write_followers)
          whitelist.concat(['entity', 'profile', 'public', 'groups'])

          if authorized_scopes.include?(:write_secrets)
            whitelist.concat(['mac_key_id', 'mac_key', 'mac_algorithm', 'mac_timestamp_delta'])
          end
        end
        follower.update(data.slice(*whitelist))
        if data['types']
          follower.notification_subscriptions.destroy
          data['types'].each do |type_url|
            follower.notification_subscriptions.create(:type => type_url)
          end
        end
        follower
      end

      def self.public_attributes
        [:entity]
      end

      def permissible_foreign_key
        :follower_access_id
      end

      def core_profile
        API::CoreProfileData.new(profile)
      end

      def notification_servers
        core_profile.servers
      end

      def auth_details
        attributes.slice(:mac_key_id, :mac_key, :mac_algorithm)
      end

      def as_json(options = {})
        attributes = super

        attributes.merge!(:profile => profile) if options[:app]

        if options[:app] || options[:self]
          types = notification_subscriptions.all.map { |s| s.type.uri }
          attributes.merge!(:licenses => licenses, :types => types, :notification_path => notification_path)
        end

        attributes
      end
    end
  end
end
