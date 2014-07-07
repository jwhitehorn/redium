redis = require 'redis'
uuid  = require 'node-uuid'
async = require 'async'
crc   = require 'crc'

class RedisAdapter
  constructor: (config, connection, opts) ->
    @client = redis.createClient()
    @blank = ->
      return

  isSql: false

  #Establishes your database connection.
  connect: (callback) ->
    callback() if callback?

  #Tests whether your connection is still alive.
  ping: (callback) ->
    callback() if callback?


  #Closes your database connection.
  close: (callback) ->
    @client.end() if @client?
    callback() if callback?


  #Maps an object property to the correlated value to use for the database.
  propertyToValue: (value, property) ->
    return value


  #Maps a database value to the property value to use for the mapped object.
  valueToProperty: (value, property) ->
    if property["type"] == "number"
      return parseFloat value
    if property["type"] == "boolean"
      return value == 'true' || value == '1' || value == 1 || value == true
    return value

  on: (event, callback) ->
    return this
    #@client.on event, callback

  find: (fields, table, conditions, opts, callback) ->
    return unless callback?
    self = this
    if Object.keys(conditions).length == 0
      self.client.keys "#{table}:id:*", (err, keys) ->
        return callback(err) if err?

        self.mgetKeys keys, callback
    else if conditions["id"]?
      idValue = conditions["id"]
      self.client.hgetall "#{table}:id:#{idValue}", callback
    else
      async.reduce Object.keys(conditions), null, (existingKeys, prop, next) ->
        self.scoreRange prop, conditions, (err, lowerScore, upperScore) ->
          self.client.zrangebyscore "#{table}:#{prop}", lowerScore, upperScore, (err, keys) ->
            if existingKeys?
              next err, _.intersection existingKeys, keys
            else
              next err, keys
      , (err, keys) ->
        self.mgetKeys keys, (err, results) ->
          return callback(err) if err?
          self.recheckConditionals results, conditions, callback

  insert: (table, data, id_prop, callback) ->
    self = this
    idName = id_prop[0]["name"]
    idValue = data[idName]
    unless idValue?
      idValue = uuid.v4()
      data[idName] = idValue

    key = "#{table}:id:#{idValue}"
    self.client.hmset key, data, (err) ->
      return callback(err) if err? and callback?

      async.each Object.keys(data), (prop, next) ->
        return next() if prop == "id" #no need to index this

        score = self.score data[prop]
        self.client.zadd "#{table}:#{prop}", score, key, (err) ->
          next err
      , (err) ->
        callback(err, idName: idValue) if callback?

  update: (table, changes, conditions, callback) ->
    self = this
    callback = self.blank unless callback?
    id = conditions["id"]

    console.log "-->", changes
    console.log "==>", id
    callback()

  remove: (table, conditions, callback) ->
    callback() if callback?

  count: (table, conditions, opts, callback) ->
    callback(null, []) if callback?

  clear: (table, callback) ->
    callback() if callback?
    ##@client.del "#{table}:*", (err) ->
    ##  callback err

  eagerQuery: (association, opts, ids, callback) ->
    callback() if callback?

  score: (value) ->
    if typeof value == "number"
      return value
    if value instanceof Date
      return value.getTime()
    if typeof value == "string"
      score = parseInt crc.crc32(value), 16
      return score
    if typeof value == "boolean"
      return 1 if value == true
      return 0 if value == false
    return 0

  mgetKeys: (keys, callback) ->
    self = this
    async.map keys, (key, next) ->
      self.client.hgetall key, next
    , (err, results) ->
      callback err, results

  scoreRange: (prop, conditions, callback) ->
    value = null
    self = this
    comparator = "eq"
    if conditions[prop].sql_comparator?
      comparator = conditions[prop].sql_comparator()
      value = conditions[prop]["val"]
    else
      value = conditions[prop]

    lowerScore = "-inf"
    upperScore = "+inf"
    if comparator == "lt"
      upperScore = self.score(value) - 1
    else if comparator == "lte"
      upperScore = self.score value
    else if comparator == "gt"
      lowerScore = self.score(value) + 1
    else if comparator == "gte"
      lowerScore = self.score value
    else
      lowerScore = self.score value
      upperScore = lowerScore

    callback null, lowerScore, upperScore


  recheckConditionals: (results, conditions, callback) ->
    self = this
    async.filter results, (result, next) ->
      keep = true
      for prop in Object.keys(conditions)
        value = null
        if conditions[prop].sql_comparator?
          value = conditions[prop]["val"]
        else
          value = conditions[prop]

        if typeof value == "string"
          if result[prop] != value
            keep = false
            break

      next keep
    , (results) ->
      callback null, results

module.exports = RedisAdapter
