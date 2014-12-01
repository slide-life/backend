require_relative '../models/user'

module UserRoutes
  def self.registered(app)
    app.put '/users/:number/add_device' do
      user = User.find(number: params[:number])
      halt_with_error 404, 'User not found.' unless user

      user.update(devices: user.devices + [@request_payload['device']])
      user.to_json
    end

    app.post '/users' do
      user = User.create!(number: @request_payload['user'], devices: [@request_payload['device']])
      user.to_json
    end
  end
end
