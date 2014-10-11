local queryId         = ARGV[1]
local limit           = ARGV[2]
local offset          = ARGV[3]
local conditionsCount = ARGV[4]


for i=0,conditionsCount do
  local subKey = queryId .. i
  local offset = i*3
  local set      = ARGV[5 + offset]
  local minScore = ARGV[6 + offset]
  local maxScore = ARGV[7 + offset]
  local keys = redis.call('ZRANGEBYSCORE', set, minScore, maxScore)
  local keyCount = table.getn(keys)
  for j=0, keyCount do
    local key = keys[j+1]
    redis.call('ZINCRBY', queryId, '1', key)
  end
end

local result = redis.call('ZRANGEBYSCORE', queryId, conditionsCount, conditionsCount, 'limit', offset, limit)
redis.call('DEL', queryId)
return result
