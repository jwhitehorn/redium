adapter     = require './redis_adapter'
indexTypes  = require './index_types'

module.exports =
  adapter: adapter
  index: indexTypes
  plugin: (db, opts) ->

    beforeDefine: (model, properties, opts) ->
      return unless opts.indexes?
      for property in Object.keys(opts.indexes)
        adapter.index model, property, opts.indexes[property]
