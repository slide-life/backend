require_relative '../models/user'
require_relative '../models/identifier'
require_relative '../models/relationship'
require_relative '../models/device'

module UserRoutes
  def self.registered(app)
    app.post '/users' do
      key        = @request_payload['key']
      password   = @request_payload['password']
      identifier = @request_payload['identifier']

      halt_with_error 422, 'Requires a public key.' unless key
      halt_with_error 422, 'Requires a password.' unless password
      halt_with_error 422, 'Requires an identifier.' unless identifier and identifier['value'] and identifier['type']

      user = User.new(key: key)
      user.initialize_password(password)
      user.save! # N.B. This is required for the identifiers to persist for some reason

      begin
        user.identifiers << user.build_identifier(identifier['value'], identifier['type'])
      rescue Exception => e
        halt_with_error 422, e.message
      end

      user.save!
      user.to_json
    end

    app.get '/users' do
      halt_with_error 422, 'Requires an identifier.' unless params[:identifier]
      halt_with_error 422, 'Requires an identifier type.' unless params[:identifier_type]
      halt_with_error 422, 'Invalid identifier type.' if not IDENTIFIER_TYPES.include? params[:identifier_type].to_sym

      identifier = Identifier.find_by(value: params[:identifier], _type: _type = params[:identifier_type].capitalize, verified: true)
      if identifier then identifier.user.to_json else not_found end
    end

    app.namespace '/users/:user_id' do
      before do
        @user = User.find(params[:user_id])
        halt_with_error 404, 'User not found.' if @user.nil?
      end

      post '/identifiers/:identifier_id/verify' do
        identifier = Identifier.find(params[:identifier_id])
        verification_code = @request_payload['verification_code']

        halt_with_error 404, 'Identifier not found.' if identifier.nil?
        halt_with_error 422, 'Verification code required.' unless verification_code

        if identifier.is_a? Phone
          halt_with_error 422, 'Verification time limit exceeded' if Time.now - identifier.created > PHONE_VERIFICATION_TIME_LIMIT
          halt_with_error 422, 'Maximum number of attempts to verify phone number exceeded' if identifier.attempts >= 3
          identifier.attempts++

          if identifier.verification_code == verification_code
            identifier.verified = true
            identifier.save!
            200
          else
            halt_with_error 422, 'Invalid verification code'
            identifier.save!
          end
        end

        # TODO: verify email
      end

      post '/devices' do
        halt_with_error 422, 'Requires a device.' unless @request_payload['device']

        registration_id = @request_payload['device']['id']
        type = @request_payload['device']['type']

        halt_with_error 422, 'Requires a registration id.' unless registration_id
        halt_with_error 422, 'Requires a device type.' unless type

        case type
          when 'android'
            @user.devices << AndroidDevice.new(registration_id: registration_id)
          when 'apple'
            @user.devices << AppleDevice.new(registration_id: registration_id)
        end

        @user.save!
        @user.to_json
      end
    end
  end
end
