local queryId         = ARGV[1]
local limit           = ARGV[2]
local offset          = ARGV[3]
local conditionsCount = ARGV[4]

local function split(inputstr)
        local t={}
        local i=1
        for str in string.gmatch(inputstr, "([^,]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

local function union(arrayA, arrayB)
  local result = arrayA
  local resultCount = table.getn(result)
  local arrayBCount = table.getn(arrayB)
  for i=0, arrayBCount do
    local alreadyPresent = false
    local value = arrayB[i+1]

    for j=0, resultCount do
      if result[j+1] == value then
        alreadyPresent = true
        break
      end
    end

    if alreadyPresent == false then
      table.insert(result, value)
      resultCount = resultCount + 1
    end
  end
  return result
end


for i=0,conditionsCount do
  local offset = i*4
  local set      = ARGV[5 + offset]
  local op       = ARGV[6 + offset]
  local minScore = ARGV[7 + offset]
  local maxScore = ARGV[8 + offset]
  local keys = {}
  if op == "between" then
    keys = redis.call('ZRANGEBYSCORE', set, minScore, maxScore)
  elseif op == "in" then
    local alts = split(minScore)
    local altsCount = table.getn(alts)
    for j=0, altsCount do
      local alt = alts[j+1]
      local altKeys = redis.call('ZRANGEBYSCORE', set, alt, alt)
      keys = union(keys, altKeys)
    end
  end
  local keyCount = table.getn(keys)
  for j=0, keyCount do
    local key = keys[j+1]
    redis.call('ZINCRBY', queryId, '1', key)
  end
end

local result = redis.call('ZRANGEBYSCORE', queryId, conditionsCount, conditionsCount, 'limit', offset, limit)
redis.call('DEL', queryId)
return result
