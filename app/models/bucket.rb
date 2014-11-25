require './app/models/store.rb'

module Bucket
    include Store
    class Bucket < Store
	include Mongoid::Document
	field :key, type: String
	field :blocks, type: Array, default: []
	field :payload, type: String
	def populate(payload)
	    payload = payload
	    save!
	end

	def check_payload(payload)
	    if payload['fields']
		if payload['cipherkey']
		    if payload['fields'].keys.uniq.count != payload['fields'].keys.count
			'Duplicate fields.'
		    elsif ! payload['fields'].keys.to_set.equal?(self.blocks.to_set)
			'Fields are not the same as blocks.'
		    end
		else
		    'No cipherkey.'
		end
	    else
		'No fields.'
	    end
	end
    end
end

