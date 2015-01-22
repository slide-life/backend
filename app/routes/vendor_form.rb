require_relative '../models/vendor_form'

module VendorFormRoutes
  def self.registered(app)
    app.namespace '/vendors/:id' do
      before do
        @vendor = Vendor.find(params[:id])
        halt_with_error 404, 'Vendor not found.' if @vendor.nil?
        halt_with_error 403, 'Forbidden checksum.' unless @vendor.check_checksum(params[:checksum])
      end

      get '/vendor_forms' do
        @vendor.vendor_forms.to_json
      end

      post '/vendor_forms' do
        vendor_form = @vendor.vendor_forms.build name: @request_payload['name'],
          description: @request_payload['description'],
          form_fields: @request_payload['form_fields']
        vendor_form.save!

        vendor_form.to_json methods: [:public_key]
      end

      namespace '/vendor_forms/:form_id' do
        before do
          @vendor_form = VendorForm.find(params[:form_id])
          halt_with_error 404, 'Vendor form not found.' if @vendor_form.nil?
        end

        get do
          @vendor_form.to_json methods: [:responses, :public_key]
        end

        delete do
          @vendor_form.delete!
        end
      end
    end
  end
end
