db      = require './common/database.coffee'
chai    = require 'chai'
async   = require 'async'
orm     = require 'orm'
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


  it 'should be able to fetch all records', (done) ->
    db.open (err, models, close) ->
      models.Order.find (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exists
        orders.length.should.equal 3

        close()
        done()

  it 'should be able to fetch one record', (done) ->
    db.open (err, models, close) ->
      models.Order.one (err, order) ->
        expect(err).to.not.exist
        expect(order).to.exist
        expect(order.shipping_address).to.exist

        close()
        done()


  it 'should find total greater than 40', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.gt 40

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 2

        for order in orders
          order.total.should.be.at.least 40

        close()
        done()


  it 'should find total less than 60', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.lt 60

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 2

        for order in orders
          order.total.should.be.below 60

        close()
        done()


  it 'should find total equal to 45.95', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.eq 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1
        orders[0].total.should.equal 45.95

        close()
        done()


  it 'should find total equal to 45.95 (without comparator)', (done) ->
    db.open (err, models, close) ->
      filter =
        total: 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1
        orders[0].total.should.equal 45.95

        close()
        done()


  it 'should find total less than 45.95', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.lt 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1
        orders[0].total.should.equal 35.95

        close()
        done()


  it 'should find total greater than 45.95', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.gt 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1
        orders[0].total.should.equal 135.95

        close()
        done()


  it 'should find total less than or equal to 45.95', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.lte 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 2

        for order in orders
          order.total.should.be.at.most 45.95

        close()
        done()


  it 'should find total greater than or equal to 45.95', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.gte 45.95

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 2

        for order in orders
          order.total.should.be.at.least 45.95

        close()
        done()


  it 'should find by address', (done) ->
    db.open (err, models, close) ->
      filter =
        shipping_address: "100 Main Street"

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1
        orders[0].shipping_address.should.equal "100 Main Street"

        close()
        done()


  it 'should find by address', (done) ->
    db.open (err, models, close) ->
      filter =
        shipping_address: orm.ne "100 Main Street"

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 2

        for order in orders
          order.shipping_address.should.not.equal "100 Main Street"

        close()
        done()


  it 'should find total greater than or equal to 45.95 before the 15th', (done) ->
    db.open (err, models, close) ->
      filter =
        total: orm.gte 45.95
        order_date: orm.lt new Date Date.parse "2014-01-15T00:00:00Z"

      models.Order.find filter, (err, orders) ->
        expect(err).to.not.exist
        expect(orders).to.exist
        orders.length.should.equal 1

        for order in orders
          order.total.should.be.at.least 45.95

        close()
        done()
