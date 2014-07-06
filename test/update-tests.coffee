db      = require './common/database.coffee'
chai    = require 'chai'
async   = require 'async'
orm     = require 'orm'
crc     = require 'crc'
should  = chai.should()
expect  = chai.expect


describe 'Redis adapter find', ->

  beforeEach (done) ->
    db.reset ->
      db.open (err, models, close) ->
        async.series [
          (next) ->
            order =
              shipping_address: "100 Main St."
              total: 45.95
              order_date: new Date Date.parse "2014-01-10T04:30:00Z"
              sent_to_fullment: true

            models.Order.create order, (err) ->
              next err

          (next) ->
            order =
              shipping_address: "100 Main Street"
              total: 35.95
              order_date: new Date Date.parse "2014-01-12T04:30:00Z"
              sent_to_fullment: true

            models.Order.create order, (err) ->
              next err

          (next) ->
            order =
              shipping_address: "100 Main St."
              total: 135.95
              order_date: new Date Date.parse "2014-01-15T04:30:00Z"
              sent_to_fullment: false

            models.Order.create order, (err) ->
              next err

        ], (err) ->
          close()
          done()


  it 'should update without error', (done) ->
    db.open (err, models, close) ->
      models.Order.one (err, order) ->
        order.total = 99

        order.save (err) ->
          expect(err).to.not.exist

          close()
          done()

  it 'should update primary object record', (done) ->
    db.open (err, models, close) ->
      models.Order.one (err, order) ->
        order.total = 99

        order.save (err) ->
          models.Order.one id: order.id, (err, order) ->
            order.total.should.equal 99

            close()
            done()
