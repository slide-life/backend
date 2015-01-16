require_relative '../models/device'

module DeviceRoutes
  def self.registered(app)
    app.post '/users/:number/devices' do
      user = User.find_by(number: params[:number])
      halt_with_error 404, 'User not found.' unless user

      user.add_device(registration_id: @request_payload['registration_id'],
                      device_type: @request_payload['type'])
      user.to_json
    end
  end
end
