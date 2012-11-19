module TentD
  module Model
    class Group < Sequel::Model(:groups)
      one_to_many :permissions
    end
  end
end

module TentD
  module Model
    class XGroup
      include DataMapper::Resource
      include RandomPublicId
      include Serializable
      include UserScoped

      storage_names[:default] = "groups"

      property :id, Serial
      property :name, Text, :required => true, :lazy => false
      property :created_at, DateTime
      property :updated_at, DateTime
      property :deleted_at, ParanoidDateTime

      has n, :permissions, 'TentD::Model::Permission', :constraint => :destroy, :parent_key => :public_id

      def self.public_attributes
        [:name]
      end
    end
  end
end
