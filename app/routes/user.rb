require_relative '../models/user'

module UserRoutes
  def self.registered(app)
    app.put '/users/:id/add_device' do
      user = User.find(params[:id])
      halt_with_error 404, 'User not found.' unless user

      user.update(devices: user.devices + [@request_payload['device']])
      user.to_json
    end

    app.get '/users' do
      User.where(params).to_json
    end
  end
end
