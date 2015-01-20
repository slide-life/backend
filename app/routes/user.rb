require_relative '../models/user'

module UserRoutes
  def self.registered(app)
    app.post '/users' do
      user = User.create!(number: @request_payload['user'],
                          public_key: @request_payload['public_key'],
                          key: @request_payload['key'])
      device = @request_payload['device']
      user.add_device(registration_id: device['registration_id'],
                      device_type: device['type'])
      user.to_json
    end

    app.put '/users/:number/devices' do
      user.add_device(registration_id: @request_payload['registration_id'],
                      device_type: @request_payload['type'])
      user.to_json
    end

    app.get '/users/:number/exists' do
      user = User.find_by(number: params[:number])
      { status: !(user.nil?) }.to_json
    end

    app.get '/users/:number/public_key' do
      user = User.find_by(number: params[:number])
      { number: user.number, public_key: user.public_key }.to_json
    end

    app.get '/users/:number/profile' do
      user = User.find_by(number: params[:number])
      user.profile.to_json
    end

    app.get '/users/:number/listen' do
      user = User.find_by(number: params[:number])
      halt_with_error 404, 'User not found.' unless user
      halt_with_error 422, 'No websocket.' unless request.websocket?
      request.websocket do |ws|
        ws.onopen do
          user.listen(ws)
        end
      end
    end
  end
end

