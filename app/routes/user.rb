require_relative '../models/user'

module UserRoutes
  def self.registered(app)
    app.post '/users' do
      user = User.create!(number: @request_payload['user'],
                          public_key: @request_payload['public_key'],
                          key: @request_payload['key'])
      user.to_json
    end

    app.namespace '/users/:number' do
      before do
        @user = User.find_by(number: params[:number])
        halt_with_error 404, 'User not found.' if @user.nil?
      end

      patch '/profile' do
        @user.patch! @request_payload['patch']
        @user.to_json
      end

      put '/devices' do
        @user.add_device(registration_id: @request_payload['registration_id'],
                        device_type: @request_payload['type'])
        @user.to_json
      end

      get '/exists' do
        { status: !(@user.nil?) }.to_json
      end

      get '/public_key' do
        { number: @user.number, public_key: @user.public_key }.to_json
      end

      get '/profile' do
        @user.profile.to_json
      end

      get '/vendor_users' do
        @user.encrypted_vendor_users.to_json
      end

      get '/listen' do
        halt_with_error 422, 'No websocket.' unless request.websocket?

        request.websocket do |ws|
          ws.onopen do
            endpoint = user.listen(ws)
            ws.onclose do
              user.unlisten endpoint
            end
          end
        end
      end
    end
  end
end

