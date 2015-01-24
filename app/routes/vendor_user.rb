require_relative '../models/vendor_user'

module VendorUserRoutes
  def self.registered(app)
    app.namespace '/vendor_users/:uuid' do
      before do
        @vendor_user = VendorUser.find_by(uuid: params[:uuid])
        halt_with_error 404, 'Vendor user not found' if @vendor_user.nil?
        puts "Checksum: #{params['checksum']} == #{@vendor_user.checksum}"
        halt_with_error 403, 'Invalid checksum.' unless @vendor_user.check_checksum(params['checksum'])
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
        halt_with_error 422, 'No patch.' unless @request_payload['patch']

        @vendor_user.patch! @request_payload['patch']
        @vendor_user.to_json
      end
    end
  end
end
