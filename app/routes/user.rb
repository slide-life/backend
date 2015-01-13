require_relative '../models/user'

module UserRoutes
  def self.registered(app)
    app.put '/users/:number/add_device' do
      user = User.find_by(number: params[:number])
      halt_with_error 404, 'User not found.' unless user

      user.update(devices: user.devices + [@request_payload['device']])
      user.to_json
    end

    app.post '/users' do
      user = User.create!(
        number: @request_payload['user'],
        devices: [@request_payload['device']],
        key: @request_payload['key'],
        public_key: @request_payload['public_key'])
      user.to_json
    end

    app.get '/users/:number/public_key' do
      user = User.find_by(number: params[:number])
      { number: user.number, public_key: user.public_key }.to_json
    end

    app.get '/users/:number/profile' do
      number = params[:number]
      user = User.find_by(number: number)
      user.profile.to_json
    end
  end
end

