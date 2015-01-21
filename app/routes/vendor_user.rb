require_relative '../models/vendor_user'

module VendorUserRoutes
  def self.registered(app)
    app.post '/vendors/:id/vendor_users' do
      vendor = Vendor.find(params[:id])
      #TODO: invite code or some form of authentication
      vendor_user = vendor.vendor_users.build ({
        key: @request_payload['key'],
        public_key: @request_payload['public_key'],
        checksum: @request_payload['checksum']
      })
      vendor_user.uuid = (0...32).map{65.+(rand(25)).chr}.join
      vendor_user.save!
      vendor.patch_key!(vendor_user, vendor_user.key, @request_payload['vendor_key'])

      vendor_user.to_json
    end

    app.get '/vendors/:id/vendor_users/:uuid/profile' do
      vendor = Vendor.find(params[:id])
      vendor_user = VendorUser.find(params[:uuid])

      vendor_user.vendor_profile.to_json
    end

    app.get '/vendors/:id/vendor_users/:uuid/latest_profile' do
      vendor = Vendor.find(params[:id])
      vendor_user = VendorUser.find_by(uuid: params[:uuid])

      vendor_user.vendor_latest_profile.to_json
    end

    app.get '/vendor_users/:uuid/vendor_forms' do
      vendor_user = VendorUser.find_by(uuid: params[:uuid])
      vendor_forms = vendor_user.vendor_forms

      vendor_forms.to_json
    end

    app.get '/vendor_users/:uuid' do
      vendor_user = VendorUser.find_by(uuid: params[:uuid])
      vendor_user.to_json
    end

    app.get '/vendor_users/:uuid/profile' do
      vendor_user = VendorUser.find_by(uuid: params[:uuid])

      vendor_user.profile.to_json
    end

    app.patch '/vendor_users/:uuid/profile' do
      vendor_user = VendorUser.find_by(uuid: params[:uuid])
      vendor_user.patch! @request_payload['patch']

      vendor_user.to_json
    end
  end
end
