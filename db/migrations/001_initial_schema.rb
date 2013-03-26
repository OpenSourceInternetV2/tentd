Sequel.migration do
  change do

    # Contents:
    #   - entities
    #   - types
    #   - users
    #   - posts
    #   - apps
    #   - relationships
    #   - subscriptions
    #   - groups
    #   - mentions
    #   - attachments
    #   - posts_attachments
    #   - permissions

    create_table(:entities) do
      primary_key :id

      column :entity, "text", :null => false

      index [:entity], :name => :unique_entities, :unique => true
    end

    create_table(:types) do
      primary_key :id

      column :type     , "text" , :null => false
      column :fragment , "text"

      index [:type, :fragment], :name => :unique_types, :unique => true
    end

    create_table(:users) do
      primary_key :id
      foreign_key :entity_id, :entities

      column :entity, "text", :null => false # entities.entity

      index [:entity], :name => :unique_users, :unique => true
    end

    create_table(:posts) do
      primary_key :id
      foreign_key :user_id          , :users
      foreign_key :type_id          , :types
      foreign_key :type_fragment_id , :types
      foreign_key :entity_id        , :entities

      column :type                 , "text"                   , :null => false # types.type + '#' + types.fragment
      column :entity               , "text"                   , :null => false # entities.entity
      column :original_entity      , "text"

      # Timestamps
      # nanoseconds since unix epoch
      # bigint max value: 9,223,372,036,854,775,807

      column :published_at         , "bigint"                 , :null => false
      column :received_at          , "bigint"
      column :deleted_at           , "bigint"
      column :version_published_at , "bigint"
      column :version_received_at  , "bigint"

      column :app_id               , "text"
      column :app_name             , "text"
      column :app_url              , "text"

      column :permissions_entities , "text[]"                 , :default => "{}"
      column :permissions_groups   , "text[]"                 , :default => "{}"

      column :mentions             , "text" # serialized json
      column :attachments          , "text" # serialized json

      column :version_parents      , "text" # serialized json
      column :version              , "text"                   , :null => false
      column :version_message      , "text"

      column :public_id            , "boolean"                , :default => false
      column :licenses             , "text" # serialized json
      column :content              , "text" # serialized json

      index [:user_id], :name => :index_posts_user
      index [:user_id, :public_id], :name => :index_posts_user_public_id
      index [:user_id, :entity_id, :public_id, :version], :name => :unique_posts, :unique => true
    end

    create_table(:apps) do
      primary_key :id
      foreign_key :user_id             , :users
      foreign_key :post_id             , :posts
      foreign_key :credentials_post_id , :posts

      column :auth_code          , "text"
      column :notification_url   , "text"

      column :read_post_types    , "text[]" # members: uri
      column :read_post_type_ids , "text[]" # members: types.id
      column :write_post_types   , "text[]" # members: uri

      index [:user_id, :auth_code], :name => :index_apps_user_auth_code
      index [:user_id, :post_id], :name => :unique_app, :unique => true
    end

    create_table(:relationships) do
      primary_key :id
      foreign_key :user_id             , :users
      foreign_key :entity_id           , :entities
      foreign_key :post_id             , :posts
      foreign_key :credentials_post_id , :posts
      foreign_key :type_id             , :types # type of relationship , posts.type where posts.id = post_id

      index [:user_id, :type_id], :name => :index_relationships_user_type
      index [:user_id, :post_id], :name => :unique_relationships, :unique => true
    end

    create_table(:subscriptions) do
      primary_key :id
      foreign_key :user_id         , :users
      foreign_key :post_id         , :posts
      foreign_key :relationship_id , :relationships
      foreign_key :type_id         , :types

      index [:user_id, :type_id], :name => :index_subscriptions_user_type
      index [:user_id, :relationship_id, :post_id, :type_id], :name => :unique_subscriptions, :unique => true
    end

    create_table(:groups) do
      primary_key :id
      foreign_key :user_id , :users
      foreign_key :post_id , :posts

      index [:user_id, :post_id], :name => :unique_groups, :unique => true
    end

    create_table(:mentions) do
      foreign_key :user_id   , :users
      foreign_key :post_id   , :posts
      foreign_key :entity_id , :entities

      column :post   , "text"    , :null => false
      column :public , "boolean" , :default => true

      primary_key [:user_id, :entity_id, :post]
    end

    # Fallback data store for attachments
    # metadata is kept in posts.attachment as serialized json
    #
    # No need to scope by user as attachment data is immutable
    create_table(:attachments) do
      primary_key :id

      column :hash         , "text"   , :null => false
      column :size         , "bigint" , :null => false
      column :data         , "bytea"  , :null => false

      index [:hash, :size], :name => :unique_attachments, :unique => true
    end

    # Join table for post attachment data
    create_table(:posts_attachments) do
      foreign_key :post_id       , :posts       , :on_delete => :cascade
      foreign_key :attachment_id , :attachments , :on_delete => :cascade

      primary_key [:post_id, :attachment_id], :name => :unique_posts_attachments, :unique => true
    end

    create_table(:permissions) do
      foreign_key :user_id   , :users
      foreign_key :post_id   , :posts
      foreign_key :entity_id , :entities
      foreign_key :group_id  , :groups

      index [:user_id, :post_id, :entity_id, :group_id], :name => :unique_permissions, :unique => true
    end

  end
end