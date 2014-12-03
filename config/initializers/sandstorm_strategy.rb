module Devise
  module Strategies
    class Sandstorm < Authenticatable
      def authenticate!
        puts 'Authenticating Sandstorm'
        userid = request.headers['HTTP_X_SANDSTORM_USER_ID']

        u = User.where(username: userid).first
        if !u
          opts = {}
          opts[:username] = userid
          opts[:email] = request.headers['HTTP_X_SANDSTORM_USERNAME']
          opts[:language] = I18n.locale.to_s # TODO(soon): change this to read from headers
          u = User.create(opts)
          u.set_person(Person.new({}))
          u.generate_keys
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
