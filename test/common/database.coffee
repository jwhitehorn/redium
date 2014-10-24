orm    = require 'orm'
redis  = require '../../src/redis_adapter.coffee'
client = require('redis').createClient()

class Database
  @open: (callback) ->
    orm.addAdapter 'redis', redis

    orm.connect 'redis://localhost:6380', (err, db)->
      return callback(err) if err?

      db.defineType 'LowerCaseString',
          datastoreType: (prop) ->
            return 'TEXT'

          valueToProperty: (value, prop) ->
            return value

          propertyToValue: (value, prop) ->
            return null unless value?
            return value.toLowerCase()

      db.settings.set 'instance.cache', false
      order = db.define "orders",
                      shipping_address: String
                      total: Number
                      order_date: Date
                      sent_to_fullment: Boolean
                      status_code: "LowerCaseString"

      lineItem = db.define "line_items",
                      order_id: String
                      quantity: Number
                      product_description: String

      lineItem.hasOne "order", order, reverse: "items"

      models =
        Order: order
        LineItem: lineItem

      callback null, models, ->
        db.close()

  @reset: (callback) ->
    client.keys "*", (err, allKeys) ->
      client.del allKeys, (err) ->
        callback err

module.exports = Database
