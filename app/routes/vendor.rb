require_relative '../models/vendor'

module VendorRoutes
  def self.registered(app)
    app.put '/vendors/:id' do
      @vendor = Vendor.find(params[:id])
      halt_with_error 404, 'Vendor not found.' if @vendor.nil?
      halt_with_error 403, 'Invalid invite code.' unless @vendor.check_invite_code(@request_payload['invite_code'])
      ['key', 'public_key', 'checksum'].each do |field|
        halt_with_error 422, "#{field} not present." unless @request_payload[field]
      end

      @vendor.update! key: @request_payload['key'],
        public_key: @request_payload['public_key'],
        checksum: @request_payload['checksum']
      @vendor.to_json
    end

    app.namespace '/vendors/:id' do
      before do
        @vendor = Vendor.find(params[:id])
        halt_with_error 404, 'Vendor not found.' if @vendor.nil?
      end

      get '/profile' do
        @vendor.profile.to_json
      end

      patch '/profile' do
        halt_with_error 403, 'Invalid checksum.' unless @vendor.check_checksum(@request_payload['checksum'])
        halt_with_error 422, 'No patch.' unless @request_payload['patch']

        @vendor.patch! @request_payload['patch']
        @vendor.to_json
      end

      get '/vendor_keys' do
        { vendor_keys: @vendor.vendor_keys }.to_json
      end

      get '/vendor_users' do
        halt_with_error 403, 'Invalid checksum.' unless @vendor.check_checksum(params['checksum'])
        @vendor.vendor_users.to_json
      end

      post '/vendor_users' do
        halt_with_error 403, 'Invalid checksum.' unless @vendor.check_checksum(@request_payload['checksum'])
        #TODO: invite code or some form of authentication
        ['key', 'public_key', 'checksum'].each do |field|
          halt_with_error 422, "#{field} not present." unless @request_payload[field]
        end

        vendor_user = @vendor.vendor_users.build ({
          key: @request_payload['key'],
          public_key: @request_payload['public_key'],
          checksum: @request_payload['login_checksum'],
          vendor_key: @request_payload['vendor_key']
        })
        vendor_user.uuid = (0...32).map{65.+(rand(25)).chr}.join
        vendor_user.save!

        vendor_user.to_json
      end

      namespace '/vendor_users/:uuid' do
        before do
          @vendor_user = VendorUser.find(params[:uuid])
          halt_with_error 404, 'Vendor user not found' if @vendor_user.nil?
          halt_with_error 403, 'Invalid checksum.' unless @vendor.check_checksum(@request_payload['checksum'])
        end

        get '/profile' do
          @vendor_user.vendor_profile.to_json
        end

        get '/latest_profile' do
          @vendor_user.vendor_latest_profile.to_json
        end
      end
    end
  end
end
