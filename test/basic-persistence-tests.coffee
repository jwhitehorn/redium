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
