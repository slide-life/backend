require_relative 'store'

class Channel < Store
  include Mongoid::Document
  field :key, type: String
  field :blocks, type: Array, default: []
  field :buckets, type: Array, default: []
  field :open, type: Boolean, default: false

  def stream(payload)
    notify(payload)
  end

  def check_payload(payload)
    puts "Inspecting #{payload}"
    if payload['fields']
      if payload['cipherkey']
        if payload['fields'].keys.uniq.count != payload['fields'].keys.count
          'Duplicate fields.'
        elsif !payload['fields'].keys.to_set.subset?(self.blocks.to_set)
          'Fields are not subset of blocks.'
        else
          :ok
        end
      else
        'No cipherkey.'
      end
    else
      'No fields.'
    end
  end
end
