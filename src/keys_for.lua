local queryId         = ARGV[1]
local limit           = ARGV[2]
local offset          = ARGV[3]
local conditionsCount = ARGV[4]

--perform ZCOUNT on first set
--ZUNIONSTORE queryId, count, firstSetName
--   -> store the result in new count (omg, can't perform in parallel! - perhaps not? not sure how INTERSTORE will like count > input set size, surely it can handle it, right???)
--for each remaining set, perform ZINTERSTORE queryId, count, queryId, nextSetName
--finally, perform ZRANGEBYSCORE on the queryId set

--clean up: DEL queryId

--[[
local set = ARGV[5]
local min = ARGV[6]
local max = ARGV[7]
local keys = redis.call('ZRANGEBYSCORE', set, min, max)
for j=0, table.getn(keys) do
  local key = keys[j+1]
  redis.call('ZADD', queryId, 1, key)
end
local result = redis.call('ZRANGE', queryId, offset, limit)
redis.call('DEL', queryId)
return result
--]]


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
    --redis.call('ZADD', subKey, 1, key)
    redis.call('ZADD', queryId, 1, key)
  end
  --redis.call('ZINTERSTORE', queryId, keyCount, queryId, subKey)
  --redis.call('DEL', subKey)
end

local result = redis.call('ZRANGE', queryId, offset, limit)
redis.call('DEL', queryId)
return result
