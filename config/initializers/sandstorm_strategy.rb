require 'securerandom'

module Devise
  module Strategies
    class Sandstorm < Authenticatable
      def authenticate!
        puts 'Authenticating Sandstorm'
        userid = request.headers['HTTP_X_SANDSTORM_USER_ID'].encode(Encoding::UTF_8)

        u = User.where(invitation_token: userid).first
        if !u
          opts = {}
          opts[:username] = userid
          opts[:invitation_token] = userid
          opts[:email] = 'none@example.com'
          opts[:language] = I18n.locale.to_s # TODO(soon): change this to read from headers
          opts[:password] = SecureRandom.hex
          u = User.build(opts)

          name = URI.unescape(request.headers['HTTP_X_SANDSTORM_USERNAME']).force_encoding(Encoding::UTF_8)
          space_index = name.index(' ')
          if space_index
            u.person.profile.first_name = name[0..space_index]
            u.person.profile.last_name = name[space_index+1..-1]
          else
            u.person.profile.first_name = name
          end
        end

        puts 'Done Authenticating Sandstorm'
        success!(u)
      end

      def valid?
        !!request.headers['HTTP_X_SANDSTORM_USER_ID']
      end
    end
  end
end
