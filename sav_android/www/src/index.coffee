

class App
    # Application Constructor
    constructor: () ->
        this.bindEvents()
    
    # Bind any events that are required on startup. Common events are:
    # 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: () ->
        document.addEventListener('deviceready', this.onDeviceReady, false)

    # The scope of 'this' is the event. In order to call the 'receivedEvent'
    # function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: () ->
        app.receivedEvent('deviceready')

    # Update DOM on a Received Event
    receivedEvent: (id) -> 
        alert(id)
        console.log('Received Event: ' + id)

window.App = App
