require_relative '../models/vendor_form'

module VendorFormRoutes
  def self.registered(app)
    app.get '/vendors/:id/vendor_forms' do
      vendor = Vendor.find(params[:id])
      halt_with_error 403, 'Forbidden checksum.' unless vendor.check_checksum(@request_payload['checksum'])

      vendor.vendor_forms.to_json
    end

    app.post '/vendors/:id/vendor_forms' do
      vendor = Vendor.find(params[:id])
      halt_with_error 403, 'Forbidden checksum.' unless vendor.check_checksum(@request_payload['checksum'])

      vendor_form = vendor.vendor_forms.build name: @request_payload['name'],
        description: @request_payload['description'],
        form_fields: @request_payload['form_fields']
      vendor_form.save!

      vendor_form.to_json methods: [:public_key]
    end

    app.get '/vendors/:id/vendor_forms/:form_id' do
      vendor = Vendor.find(params[:id])
      halt_with_error 403, 'Forbidden checksum.' unless vendor.check_checksum(@request_payload['checksum'])

      vendor_form = VendorForm.find(params[:form_id])
      vendor_form.to_json methods: [:responses, :public_key]
    end
  end
end
