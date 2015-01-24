require_relative '../models/vendor'

module VendorRoutes
  def self.registered(app)
    app.namespace '/vendors/:id' do
      before do
        @vendor = Vendor.find(params[:id])
        halt_with_error 404, 'Vendor not found.' if @vendor.nil?
      end

      get '/public_key' do
        { public_key: @vendor.public_key }.to_json
      end

      put do
        halt_with_error 403, 'Invalid invite code.' unless @vendor.check_invite_code(@request_payload['invite_code'])
        ['key', 'public_key', 'checksum'].each do |field|
          halt_with_error 422, "#{field} not present." unless @request_payload[field]
        end

        @vendor.update! key: @request_payload['key'],
          public_key: @request_payload['public_key'],
          checksum: @request_payload['checksum']
        @vendor.to_json
      end

      namespace '' do #authenticated
        before do
          halt_with_error 403, 'Invalid checksum.' unless @vendor.check_checksum(params['checksum'])
        end

        get '/profile' do
          @vendor.profile.to_json
        end

        patch '/profile' do
          halt_with_error 422, 'No patch.' unless @request_payload['patch']

          @vendor.patch! @request_payload['patch']
          @vendor.to_json
        end

        get '/vendor_keys' do
          { vendor_keys: @vendor.vendor_keys }.to_json
        end
      end
    end
  end
end
