require_relative '../models/block'

DEFAULT_ORGANIZATION = 'slide.life'

def path_of(name)
  if name.include? ':'
    return name.split(':')[1]
  else
    return name
  end
end

def separate_path(name)
  name.split('.')
end

def full_name(name)
  if name.include? ':'
    return name
  else
    "#{DEFAULT_ORGANIZATION}:#{name}"
  end
end

def component_name(name)
  separate_path(path_of(name)).last
end

def resolve(block_schema, name)
  real_name = full_name(name)

  path = path_of(real_name)
  split_path = separate_path(path)

  starting = block_schema
  while starting[split_path.first]
    starting = starting[split_path.first]
    split_path = split_path[1..-1]
  end

  if split_path.empty?
    return real_name
  end

  inherits(starting).each do |inheritance|
    result = resolve(block_schema, ([inheritance] + split_path).join('.'))
    return result if result
  end

  components(starting).select do |component|
    component_name(component) == split_path.first
  end.each do |component|
    return resolve(block_schema, ([component] + split_path[1..-1]).join('.'))
  end
end

def resolve_field(block_schema, name)
  puts "Resolving field: #{name}"
  real_name = resolve(block_schema, name)
  path = path_of(real_name)
  return separate_path(path).reduce(block_schema) do |memo, obj|
    memo[obj]
  end
end

def children(hash)
  hash.keys.select { |key| key[0] != '_' } || []
end

def components(hash)
  hash['_components'] || []
end

def inherits(hash)
  if hash['_inherits']
    [hash['_inherits']]
  else
    []
  end
end

def dependencies(block_schema, field)
  Hash[
    children(field).map { |child| [child, field[child]] } +
    (components(field) + inherits(field)).map do |c|
      [resolve(block_schema, c), resolve_field(block_schema, c)]
    end
  ]
end

def validate_field(block_schema, current, key, seen, stack)
  return false if stack.include?(key)
  added_to_stack = stack + [key]

  return true if seen[key]
  seen[key] = true

  dependencies(block_schema, current).each do |key, value|
    return false unless validate_field(
      block_schema,
      value,
      key,
      seen,
      added_to_stack
    )
  end

  true
end

def validate_schema(block_schema)
  seen = {}
  children(block_schema).each do |child|
    resolved = resolve(block_schema, child)
    result = validate_field(block_schema, block_schema[child],
                            resolved, seen, [])
    return false unless result
  end

  true
end

module BlockRoutes
  def self.registered(app)
    app.get '/blocks' do
      organization = params['organization'] || DEFAULT_ORGANIZATION
      blocks = Block.find_by(organization: organization)
      halt_with_error 404, 'Organisation not found' if blocks.nil?

      halt_with_error 422, 'Invalid schema' unless validate_schema(blocks.schema)

      blocks.to_json
    end
  end
end
