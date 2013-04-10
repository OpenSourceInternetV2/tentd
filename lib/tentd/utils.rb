module TentD
  module Utils

    MAC_ALGORITHM = "hmac-sha-256".freeze

    def self.random_id
      SecureRandom.urlsafe_base64(16)
    end

    def self.mac_key
      SecureRandom.hex(32)
    end

    def self.mac_algorithm
      MAC_ALGORITHM
    end

    def self.hex_digest(io)
      io = StringIO.new(io) if String === io

      digest = Digest::SHA512.new
      while buffer = io.read(1024)
        digest << buffer
      end
      io.rewind
      digest.hexdigest[0...64]
    end

    def self.timestamp
      (Time.now.to_f * 1000).to_i
    end

    def self.expand_uri_template(template, params = {})
      template.to_s.gsub(/{([^}]+)}/) { URI.encode_www_form_component(params[$1] || params[$1.to_sym]) }
    end

    module Hash
      extend self

      def slice(hash, *keys)
        keys.each_with_object(hash.class.new) { |k, new_hash|
          new_hash[k] = hash[k] if hash.has_key?(k)
        }
      end

      def slice!(hash, *keys)
        hash.replace(slice(hash, *keys))
      end

      def stringify_keys(hash)
        _stringify_keys(hash).first
      end

      def _stringify_keys(*items)
        items.map do |item|
          case item
          when ::Hash
            item.inject(::Hash.new) do |new_hash, (k,v)|
              new_hash[k.to_s] = _stringify_keys(v).first
              new_hash
            end
          when ::Array
            item.map { |i| _stringify_keys(i).first }
          else
            item
          end
        end
      end

      def stringify_keys!(hash)
        hash.replace(stringify_keys(hash))
      end
    end

  end
end
