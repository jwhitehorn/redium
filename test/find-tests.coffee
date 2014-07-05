db      = require './common/database.coffee'
chai    = require 'chai'
async   = require 'async'
should  = chai.should()
expect  = chai.expect


describe 'Redis adapter find', ->

  beforeEach (done) ->
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


  it 'should be able to fetch all records', (done) ->
    db.open (err, models, close) ->
      models.Order.find (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exists
        orders.length.should.equal 3

        close()
        done()
