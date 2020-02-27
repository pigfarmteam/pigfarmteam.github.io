const mongoose = require('mongoose');

const KeyValue = mongoose.model('KeyValue', {
  key: {
    type: String,
    unique: true,
    index: true
  },
  value: String
});

const BetError = mongoose.model('BetError', {
  betIndex: {
    type: String,
    unique: true,
    index: true
  }
});

module.exports = {
  connect() {
    return new Promise((resolve, reject) => {
      console.log('Try to connect', process.env.MONGODB_URI);
      mongoose.connect(process.env.MONGODB_URI, {
        useNewUrlParser: true,
        useCreateIndex: true
      }, (err) => {
        if (err) return reject(err);
        else return resolve(resolve);
      });
    })
  },
  put: async (key, value) => {
    await KeyValue.create({
      key: key,
      value: value
    });
    var v = await KeyValue.findOne({key: key});
    if (v.value == value) {
      return value;
    }
    else {
      throw new Error('Cannot save to database');
    }
  },
  set: async (key, value) => {
    await KeyValue.updateOne({
      key: key
    }, {
      key: key,
      value: value
    }, {
      upsert: true
    });
    var v = await KeyValue.findOne({key: key});
    if (v.value == value) {
      return value;
    }
    else {
      throw new Error('Cannot save to database');
    }
  },
  get: async (key) => {
    var v = await KeyValue.findOne({key: key});
    if (!v) throw new Error("Cannot found value with key", key);
    return v.value;
  },
  addBetError: async (betIndex) => {
    return await BetError.updateOne({
      betIndex
    }, {
      betIndex
    }, {
      upsert: true
    });
  },
  removeBetError: async (betIndex) => {
    return await BetError.deleteOne({
      betIndex
    });
  },
  getIndexOfBetError: async() => {
    var bet = await BetError.findOne({});
    if (bet) {
      return bet.betIndex;
    }
    else {
      return 0;
    }
  }
}