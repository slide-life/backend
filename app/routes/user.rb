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

    app.get '/users/:number/exists' do
      user = User.find_by(number: params[:number])
      { status: !(user.nil?) }.to_json
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

