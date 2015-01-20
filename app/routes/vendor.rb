require_relative '../models/vendor'

module VendorRoutes
  def self.registered(app)
    app.get '/vendors/:id' do
      vendor = Vendor.find(params[:id])

      vendor.profile.to_json
    end

    app.put '/vendors/:id' do
      vendor = Vendor.find(params[:id])
      halt_with_error 403, 'Invalid invite code.' unless vendor.check_invite_code(params['invite_code'])

      vendor.update! key: @request_payload['key'],
        public_key: @request_payload['public_key'],
        checksum: @request_payload['checksum']
      vendor.to_json
    end

    app.patch '/vendors/:id' do
      vendor = Vendor.find(params[:id])
      halt_with_error 403, 'Invalid checksum.' unless vendor.check_checksum(params['checksum'])

      vendor.patch! params['patch']

      vendor.to_json
    end
  end
end
