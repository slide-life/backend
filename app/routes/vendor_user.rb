require_relative '../models/vendor_user'

module VendorUserRoutes
  def self.registered(app)
    app.namespace '/vendors/:id' do
      before do
        @vendor = Vendor.find(params[:id])
        halt_with_error 404, 'Vendor not found' if @vendor.nil?
      end

      post '/vendor_users' do
        #TODO: invite code or some form of authentication
        vendor_user = @vendor.vendor_users.build ({
          key: @request_payload['key'],
          public_key: @request_payload['public_key'],
          checksum: @request_payload['checksum']
        })
        vendor_user.uuid = (0...32).map{65.+(rand(25)).chr}.join
        vendor_user.save!
        @vendor.patch_key!(@vendor_user, @request_payload['vendor_key'])

        vendor_user.to_json
      end

      namespace '/vendor_users/:uuid' do
        before do
          @vendor_user = VendorUser.find(params[:uuid])
          halt_with_error 404, 'Vendor user not found' if @vendor_user.nil?
          halt_with_error 403, 'Invalid checksum.' unless @vendor_user.check_checksum(@request_payload['checksum'])
        end

        get '/profile' do
          @vendor_user.vendor_profile.to_json
        end

        get '/latest_profile' do
          @vendor_user.vendor_latest_profile.to_json
        end
      end
    end

    app.namespace '/vendor_users/:uuid' do
      before do
        @vendor_user = VendorUser.find_by(uuid: params[:uuid])
        halt_with_error 404, 'Vendor user not found' if @vendor_user.nil?
        halt_with_error 403, 'Invalid checksum.' unless @vendor_user.check_checksum(@request_payload['checksum'])
      end

      get do
        @vendor_user.to_json
      end

      get '/vendor_forms' do
        @vendor_user.vendor_forms.to_json
      end

      get '/vendor_users/:uuid/profile' do
        @vendor_user.profile.to_json
      end

      patch '/vendor_users/:uuid/profile' do
        @vendor_user.patch! @request_payload['patch']
        @vendor_user.to_json
      end
    end
  end
end
