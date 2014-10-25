redis      = require 'redis'
uuid       = require 'node-uuid'
async      = require 'async'
crc        = require 'crc'
fs         = require 'fs'
path       = require 'path'
_          = require 'underscore'
indexTypes = require './index_types'

commands = {}
indexOptions = {}

class RedisAdapter
  constructor: (config, connection, opts) ->
    @client = redis.createClient()
    @customTypes = {}
    @blank = ->
      return

  isSql: false

  @index: (model, property, indexType) ->
    modelOptions = indexOptions[model]
    modelOptions = {} unless modelOptions?
    modelOptions[property] = indexType
    indexOptions[model] = modelOptions

  #Establishes your database connection.
  connect: (callback) ->
    self = this
    rootPath = path.dirname(fs.realpathSync(__filename))
    async.series [
      (next) ->
        return next() if commands.keysFor?
        filename = path.join rootPath, "./keys_for.lua"
        fs.readFile filename, 'utf8', (err, lua) ->
          return callback?(err) if err?

          self.client.script 'load', lua, (err, sha) ->
            commands.keysFor = sha
            next(err)

      (next) ->
        return next() if commands.mhgetAll?
        filename = path.join rootPath, "./mhgetall.lua"
        fs.readFile filename, 'utf8', (err, lua) ->
          return callback?(err) if err?

          self.client.script 'load', lua, (err, sha) ->
            commands.mhgetAll = sha
            next(err)

      (next) ->
        return next() if commands.createIndex?
        filename = path.join rootPath, "./create_index.lua"
        fs.readFile filename, 'utf8', (err, lua) ->
          return callback?(err) if err?

          self.client.script 'load', lua, (err, sha) ->
            commands.createIndex = sha
            next(err)

      (next) ->
        return next() if commands.updateIndex?
        filename = path.join rootPath, "./update_index.lua"
        fs.readFile filename, 'utf8', (err, lua) ->
          return callback?(err) if err?

          self.client.script 'load', lua, (err, sha) ->
            commands.updateIndex = sha
            next(err)

      (next) ->
        return next() if commands.delete?
        filename = path.join rootPath, "./delete.lua"
        fs.readFile filename, 'utf8', (err, lua) ->
          return callback?(err) if err?

          self.client.script 'load', lua, (err, sha) ->
            commands.delete = sha
            next(err)

    ], (err) ->
      alreadyConfiguredLua = true
      callback(err) if callback?

  #Tests whether your connection is still alive.
  ping: (callback) ->
    callback() if callback?


  #Closes your database connection.
  close: (callback) ->
    @client.quit() if @client?
    callback() if callback?


  #Maps an object property to the correlated value to use for the database.
  propertyToValue: (value, property) ->
    typeHandler = @customTypes[property.type]
    if typeHandler and "propertyToValue" of typeHandler
      return typeHandler.propertyToValue(value)

    return value


  #Maps a database value to the property value to use for the mapped object.
  valueToProperty: (value, property) ->
    if property["type"] == "number"
      v = parseFloat value
      if isNaN(v)
        v = null
      return v
    if property["type"] == "boolean"
      return value == 'true' || value == '1' || value == 1 || value == true
    if property["type"] == "text"
      if value == 'null'
        return null
    if property["type"] == "date"
      return null unless value?
      v = new Date Date.parse value
      if isNaN(v)
        v = null
      return v

    typeHandler = @customTypes[property.type]
    if typeHandler and "valueToProperty" of typeHandler
      return typeHandler.valueToProperty(value)

    return value

  on: (event, callback) ->
    return this
    #@client.on event, callback

  find: (fields, table, conditions, opts, callback) ->
    return unless callback?
    self = this

    self.keysFor table, conditions, opts, (err, keys) ->
      return callback(err) if err?

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

      props = Object.keys(data)
      args = [commands.createIndex, 0, props.length]
      for prop in props
        value = data[prop]
        score = self.score value
        storage = self.storageFor value
        args.push "#{table}:#{prop}"
        args.push storage
        args.push score
        args.push key

      self.client.evalsha args, (err) ->
        callback(err, idName: idValue) if callback?

  update: (table, changes, conditions, callback) ->
    self = this
    callback = self.blank unless callback?
    id = conditions["id"]

    props = Object.keys changes

    key = "#{table}:id:#{id}"
    args = [commands.updateIndex, 0, props.length]
    for prop in props
      value = changes[prop]
      score = self.score value
      storage = self.storageFor value
      args.push "#{table}:#{prop}"
      args.push prop
      args.push storage
      args.push score
      args.push value
      args.push key

    self.client.evalsha args, (err) ->
      callback err

  remove: (table, conditions, callback) ->
    self = this
    callback = self.blank unless callback?

    self.keysFor table, conditions, {}, (err, keys) ->
      return callback(err) if err?

      async.eachSeries keys, (key, next) ->
        args = [commands.delete, 0, table, key]
        self.client.evalsha args, next
      , callback

  count: (table, conditions, opts, callback) ->
    callback(null, []) unless callback?
    self = this

    self.keysFor table, conditions, opts, (err, keys) ->
      return callback(err) if err?

      callback(err, [c:keys.length])

  clear: (table, callback) ->
    self = this
    @client.keys "#{table}:*", (err, keys) ->
      return callback(err) if callback? and (err? or keys == null or keys.length == 0)
      self.client.del keys, (err) ->
        callback(err) if callback?

  eagerQuery: (association, opts, ids, callback) ->
    callback() if callback?

  score: (value) ->
    if typeof value == "string"
      score = parseInt crc.crc32(value), 16
      return score
    unless value? and isNaN(value) ==false
      return "-inf"
    if typeof value == "number"
      return value
    if value instanceof Date
      return value.getTime()
    if typeof value == "boolean"
      return 1 if value == true
      return 0 if value == false
    return 0

  storageFor: (value) ->
    if typeof value == "boolean"
      return indexTypes.discrete

    return indexTypes.series

  mgetKeys: (keys, callback) ->
    self = this
    args = [commands.mhgetAll, 0, keys.length].concat keys

    self.client.evalsha args, (err, rawResults) ->
      results = []
      if rawResults?
        for rawResult in rawResults
          obj = {}
          i = 0
          while i isnt rawResult.length
            obj[rawResult[i]] = rawResult[i+1]
            i += 2
          results.push obj
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

    storage = self.storageFor value
    lowerScore = "-inf"
    upperScore = "+inf"
    if comparator == "ne"
      err = new Error "Unsupported operator"
      err.code = 4001
      return callback err
    else if comparator == "lt"
      upperScore = self.score(value) - 1
    else if comparator == "lte"
      upperScore = self.score value
    else if comparator == "gt"
      lowerScore = self.score(value) + 1
    else if comparator == "gte"
      lowerScore = self.score value
    else if comparator == "between"
      lowerScore = self.score(conditions[prop]["from"])
      upperScore = self.score(conditions[prop]["to"])
    else
      if value.length? and typeof value is 'object'
        scores = []
        for v in value
          scores.push self.score v
        return callback null, storage, scores, null

      lowerScore = self.score value
      upperScore = lowerScore

    callback null, storage, lowerScore, upperScore


  keysFor: (table, conditions, opts, callback) ->
    limit = opts.limit if typeof opts.limit == "number"
    offset = opts.offset if typeof opts.offset == "number"
    self = this
    if conditions == null or Object.keys(conditions).length == 0
      self.performZRangeByScore "#{table}:id", "-inf", "inf", limit, offset, (err, keys) ->
        callback err, keys
    else if conditions["id"]?
      idValue = conditions["id"]
      callback null, ["#{table}:id:#{idValue}"]
    else
      async.map Object.keys(conditions), (prop, next) ->
        #first, let's convert node-orm's conditions from a hash, to an array with redis scores
        self.scoreRange prop, conditions, (err, storage, lowerScore, upperScore) ->
          return next(err) if err?

          if storage == indexTypes.discrete
            op = "set"
          else if lowerScore.length? and typeof lowerScore is 'object'
            op = "in"
            lowerScore = lowerScore.join ','
          else
            op = "between"
          next err, ["#{table}:#{prop}", op, lowerScore, upperScore]

      , (err, conditions) ->
        return callback(err) if err?
        #now that we have an array we can pass to redis, let's call our Lua function
        queryId = uuid.v4()
        offset = 0 unless offset?
        limit = 999999 unless limit?
        args = [commands.keysFor, 0, queryId, limit, offset, conditions.length].concat _.flatten(conditions)
        self.client.evalsha args, (err, keys) ->
          if keys == "ERROR"
            err = new Error "Query too large"
            err.code = 4000
            return callback err
          callback err, keys


  performZRangeByScore: (key, min, max, limit, offset, callback) ->
    args = [key, min, max]
    if limit? or offset?
      args.push "LIMIT"
      args.push offset if offset?
      args.push 0 unless offset?
      args.push limit if limit?
    args.push callback
    @client.zrangebyscore.apply @client, args


  recheckConditionals: (results, conditions, callback) ->
    self = this
    results = [] unless results?
    async.filter results, (result, next) ->
      keep = true
      return next(false) unless result?
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
