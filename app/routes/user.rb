require 'json'

require_relative '../models/user'
require_relative '../models/identifier'
require_relative '../models/relationship'

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
      user.initializePassword(password)

      begin
        user.addIdentifier(identifier['value'], identifier['type'].to_sym)
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
        halt_with_error 404, 'Actor not found.' if @user.nil?
      end

      get '' do
        @user.to_json
      end

      get '/relationships' do
        Relationship.or({ left: @user}, {right: @user }).to_json
      end
    end
  end
end
