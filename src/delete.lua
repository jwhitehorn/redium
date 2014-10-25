local model = ARGV[1]
local key   = ARGV[2]

local properties = redis.call('HKEYS', key)

for i=1, table.getn(properties) do
  local prop = properties[i]
  local indexKey = model .. ':' .. prop
  local type = redis.call('TYPE', indexKey)
  if type == 'set' then
    redis.call('SREM', indexKey, key)
  elseif type == 'zset' then
    redis.call('ZREM', indexKey, key)
  end
end

redis.call('ZREM', model .. ':id', key)
redis.call('DEL', key)
