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

      begin
        user.add_identifier(identifier['value'], identifier['type'])
      rescue Exception => e
        halt_with_error 422, e.message
      end

      user.save!
      user.to_json
    end

    app.get '/users' do
      halt_with_error 422, 'Requires an identifier.' unless params[:identifier]
      halt_with_error 422, 'Requires an identifier type.' unless params[:identifier_type]

      identifier = Identifier.find_by(identifier: params[:identifier], type: params[:identifier_type])
      if identifier then identifier.user.to_json else not_found end
    end

    app.namespace '/users/:id' do
      before do
        @user = User.find(params[:id])
        halt_with_error 404, 'User not found.' if @user.nil?
      end

      post '/devices' do
        halt_with_error 422, 'Requires a device.' unless @request_payload['device']

        registration_id = @request_payload['device']['id']
        type = @request_payload['device']['type']

        halt_with_error 422, 'Requires a registration id.' unless registration_id
        halt_with_error 422, 'Requires a device type.' unless type

        @user.devices << Device.new(registration_id: registration_id, type: type)
        @user.save!
        @user.to_json
      end
    end
  end
end
