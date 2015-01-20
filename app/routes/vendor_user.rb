require_relative '../models/vendor_user'

module VendorUserRoutes
  def self.registered(app)
    app.post '/vendors/:id/vendor_users' do
      vendor = Vendor.find(params[:id])
      #TODO: invite code or some form of authentication
      vendor_user = vendor.vendor_users.build hashed_name: @request_payload['hashed_name'],
        key: @request_payload['key'],
        public_key: @request_payload['public_key'],
        checksum: @request_payload['checksum']
      vendor_user.save!
      vendor.patch!({
        '_keys' => { vendor_user.hashed_name => vendor_user.key },
        '_vendor_keys' => { vendor_user.hashed_name => @request_payload['vendor_key'] }
      })

      vendor_user.to_json
    end

    app.get '/vendors/:id/vendor_users/:user_id' do
      vendor = Vendor.find(params[:id])
      vendor_user = VendorUser.find(params[:user_id])

      vendor_user.profile.to_json
    end

    app.patch '/vendors/:id/vendor_users/:user_id' do
      vendor = Vendor.find(params[:id])
      vendor_user = VendorUser.find(params[:user_id])
      vendor_user.patch! @request_payload['patch']

      vendor_user.to_json
    end
  end
end
