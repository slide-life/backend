require_relative '../models/vendor'

module AdminRoutes
  def self.registered(app)
    app.post '/admin/vendors' do
      invite_code = (0...16).map{65.+(rand(25)).chr}.join
      vendor = Vendor.new name: @request_payload['name'],
        description: @request_payload['description'],
        invite_code: invite_code

      vendor.to_json
    end
  end
end
