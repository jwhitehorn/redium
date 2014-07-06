redis = require 'redis'
uuid  = require 'node-uuid'
async = require 'async'

class RedisAdapter
  constructor: (config, connection, opts) ->
    @client = redis.createClient()

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
      self.client.get "#{table}:id:#{idValue}", (err, json) ->
        data = []
        data = [JSON.parse(json)] if json?
        callback err, data
    else
      console.log "opts -->", opts
      console.log "conditions -->", conditions
      prop = Object.keys(conditions)[0]
      value = conditions[prop]["val"]
      comparator = conditions[prop].sql_comparator()
      console.log "comparator -->", comparator
      lowerScore = "-inf"
      upperScore = "+inf"
      if comparator == "lt"
        upperScore = self.score value
      else if comparator == "gt"
        lowerScore = self.score value
      else
        lowerScore = self.score value
        upperScore = lowerScore
      self.client.zrangebyscore "#{table}:#{prop}", lowerScore, upperScore, (err, keys) ->
        self.mgetKeys keys, callback

  insert: (table, data, id_prop, callback) ->
    self = this
    idName = id_prop[0]["name"]
    idValue = data[idName]
    unless idValue?
      idValue = uuid.v4()
      data[idName] = idValue

    key = "#{table}:id:#{idValue}"
    self.client.set key, JSON.stringify(data), (err) ->
      return callback(err) if err? and callback?

      async.each Object.keys(data), (prop, next) ->
        score = self.score data[prop]
        self.client.zadd "#{table}:#{prop}", score, key, (err) ->
          next err
      , (err) ->
        callback(err, idName: idValue) if callback?

  update: (table, changes, conditions, callback) ->
    callback() if callback?

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
    console.log "[WARN] Unsupported object (#{value}) for scoring, returning 0"
    return 0

  mgetKeys: (keys, callback) ->
    self = this
    self.client.mget keys, (err, results) ->
      return callback(err) if err?

      async.map results, (json, next) ->
        next null, JSON.parse json
      , (err, results) ->
        callback err, results


module.exports = RedisAdapter
