class InvalidBlockError < StandardError
end

class Store
  @@Sockets = {}

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(payload)
    socket = @@Sockets[self._id]
    socket.send(payload) if socket
  end

  VALID_CUSTOM_BLOCK_TYPES = ['text', 'number']

  def validate_static_blocks(blocks)
    duplicate_blocks = blocks.select { |block| blocks.count(block) > 1 }.uniq
    if duplicate_blocks.length > 0
      raise InvalidBlockError, "You cannot create a bucket with duplicate blocks. You have included #{duplicate_blocks.join(', ')} twice."
    end

    validated_blocks = Block.where(:name.in => blocks)
    unless blocks.length == validated_blocks.length
      invalid_blocks = blocks - validated_blocks.map { |block| block.name }
      raise InvalidBlockError, "The block(s) #{invalid_blocks.join(', ')} are invalid."
    end
  end

  def validate_custom_blocks(blocks)
    blocks.each do |block|
      type, name, description = block['type'], block['name'], block['description']
      raise InvalidBlockError, 'Custom block must have a description.' if description.nil? || description.empty?
      raise InvalidBlockError, "Custom block type must be one of #{VALID_CUSTOM_BLOCK_TYPES.join(', ')}." unless VALID_CUSTOM_BLOCK_TYPES.include? type
      raise InvalidBlockError, 'Custom block must have name: custom.' unless name == 'custom'
    end
  end

  def validate_blocks()
    static_blocks = self.blocks.select { |block| block.is_a? String }
    custom_blocks = self.blocks.select { |block| block.is_a? Hash }

    raise InvalidBlockError, 'You cannot create a bucket with no blocks.' if self.blocks.length == 0
    raise InvalidBlockError, 'Invalid block representation' unless static_blocks.count + custom_blocks.count == self.blocks.count

    validate_static_blocks(static_blocks)
    validate_custom_blocks(custom_blocks)
  end


  def check_payload(payload)
    return 'No fields.' unless payload['fields']
    return 'No cipherkey.' unless payload['cipherkey']
    return 'Duplicate fields.' unless payload['fields'].keys.uniq.count == payload['fields'].keys.count
    return 'Fields are not subset of blocks.' unless payload['fields'].keys.to_set.subset?(self.blocks.to_set)
      
    :ok
  end
end
