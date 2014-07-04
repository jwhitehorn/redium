redis = require 'redis'
uuid  = require 'node-uuid'
async = require 'async'

class RedisAdapter
  self = this
  constructor: (config, connection, opts) ->
    self.client = redis.createClient()

  isSql: false

  #Establishes your database connection.
  connect: (callback) ->
    callback() if callback?

  #Tests whether your connection is still alive.
  ping: (callback) ->
    callback() if callback?


  #Closes your database connection.
  close: (callback) ->
    self.client.end() if @client?
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
    console.log "-->", conditions
    idName = "id"
    idValue = conditions[idName]
    self.client.get "#{table}:#{idValue}", (err, json) ->
      data = []
      data = [JSON.parse(json)] if json?
      callback(err, data) if callback?

  insert: (table, data, id_prop, callback) ->
    idName = id_prop[0]["name"]
    idValue = data[idName]
    unless idValue?
      idValue = uuid.v4()
      data[idName] = idValue

    key = "#{table}:#{idValue}"
    self.client.set key, JSON.stringify(data), (err) ->
      return callback(err) if err? and callback?

      async.each Object.keys(data), (prop, next) ->
        score = score data[prop]
        self.client.zadd "#{table}:#{prop}", score, key, (err) ->
          console.log "#{score} err->", err
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


module.exports = RedisAdapter
