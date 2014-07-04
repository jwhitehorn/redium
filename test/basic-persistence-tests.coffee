db      = require './common/database.coffee'
chai    = require 'chai'
should  = chai.should()
expect  = chai.expect


describe 'Redis adapter inserts & basic finds', ->

  it 'should open a connection without errors', (done) ->
    db.open (err, models, close) ->
      expect(err).to.not.exist

      close()
      done()


  it 'should save model', (done) ->
    db.open (err, models, close) ->
      order =
        shipping_address: "100 Main St."
        total: 45.95
        order_date: new Date()
        sent_to_fullment: false

      models.Order.create order, (err, order) ->
        expect(err).to.not.exist
        expect(order.id).to.exist

        close()
        done()
