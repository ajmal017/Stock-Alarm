const express = require('express')
const app = express()
const port = 8080
const socket = require('socket.io-client')('https://ws-api.iextrading.com/1.0/last')
var admin = require('firebase-admin');

var symbols = []

var serviceAccount = require("//home/niclas_joswig/Stock-Alarm/stock-alarm-27fd9-firebase-adminsdk-ckcdi-05ef23eac1.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://stock-alarm-27fd9.firebaseio.com"
});

var registrationToken = 'eVuajnwLCwQ:APA91bGZhbXnGnsP5F5TwwB07AoLnpOGPPhSE02LvglYE5m1MJ_pFYQuunBvJD8xVKwpm_wm1-QuP0mm4N6JCSpUWHzWGmvIyGtU2tQZWgbd88kwjNn4j6dJ6goWs-6NdBLUif-1rhky';


class Alarm {
    constructor(symbol, level, owner, alarmId) {
        this.symbol = symbol;
        this.level = level;
        this.owner = owner;  //needed for push notification
        this.id = alarmId;
    }
    toString() {
        return "  Symbol: " + this.symbol + ", Price of Alarm: " + this.level;
    }
}

//dummy data
//Alarms = [new Alarm('AAPL', 260.0, "John", "id1"), new Alarm('GOOGL', 150, "Sarah","id2")]
symbols = ['AAPL,GOOGL']
last_prices = { 'AAPL': 259, 'GOOGL': 210 }

function notifyUser(symbol, owner, alarmId_) {
    var message = {
        notification: { title: symbol },
        data: {
            alarmId: alarmId_,
        },
        token: registrationToken
    };
    admin.messaging().send(message)
        .then((response) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
        })
        .catch((error) => {
            console.log('Error sending message:', error);
        });

}

function checkAlarms(data) {
    Alarms = []
    updateSymbol = data['symbol']
    price = data['price']
    console.log("price start:     " + price)
    console.log("last price start:   " + last_prices[updateSymbol])
    var db = admin.database();
    var ref = db.ref("Alarms").child(updateSymbol).once("value", (snapshot) => {

        //here catch all promises and return them to outer promise (promise.all)
        snapshot.forEach(function(childSnapshot) {
            //console.log(childSnapshot.val())
            var alarm = childSnapshot.val()
            Alarms.push(new Alarm(alarm.symbol, alarm.level, alarm.owner, alarm.id))
        })
    }).then((ds) => {
        //console.log(Alarms)
        for (i = 0; i < Alarms.length; i++) {
            if (Alarms[i].level < last_prices[updateSymbol]) {
                if (Alarms[i].level >= price) {
                    console.log("ALARM")
                    console.log("price:  " + price)
                    console.log("last price:   " + last_prices[updateSymbol])
                    console.log("Alarm level:    " + Alarms[i].level)
                    //notifyUser(updateSymbol,Alarms[i].owner,Alarms[i].id)
                    Alarms.splice(i, 1)
                }
            }
            else {
                if (Alarms[i].level <= data['price']) {
                    console.log("ALARM")
                    //notifyUser(updateSymbol,Alarms[i].owner,Alarms[i].id)
                    Alarms.splice(i, 1)
                }
            }
            
        }
        last_prices[updateSymbol] = price
    }).catch((reason) => console.log("failure"))
}

//todo: http get function for receiving alarm from the user

function addAlarm(symbol, level, direction, owner, alarmId) {
    Alarms.push(new Alarm(symbol, level, owner, alarmId))
}

socket.on('message', message => {
    price = JSON.parse(message);
    checkAlarms(price);
})

socket.on('connect', () => {
    socket.emit('subscribe', 'aapl')
})


socket.on('disconnect', () => console.log('Disconnected.'))

app.get('/', (req, res) => {
    res.write('<html>');
    res.write('<body>');
    //res.write(last_prices["AAPL"].toString());
    //res.write('<h1>Test price of apple: </h1>' + price['price'] + ' $ </h1><br>');
    res.write('<h1>List of Alarms: </h1>' + Alarms + ' $ <br>');
    //res.write('<h1>List of Symbols </h1>' + symbols + ' </h1><br>');
    res.write('</body>');
    res.write('</html>');
    res.end();
})

app.listen(port, () => console.log(`App listening on port ${port}!`))