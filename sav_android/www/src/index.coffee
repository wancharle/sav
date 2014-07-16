
class App
    # Application Constructor
    constructor: () ->
        this.bindEvents()
        @storage = window.localStorage
        @usuario = this.getUsuario()
   
    getUsuario: () ->
        @usuario = @storage.getItem('Usuario')
        return @usuario
    
    setUsuario: (usuario)->
        @usuario =  usuario
        @storage.setItem('Usuario',@usuario)

    temAtividadesPendentes: () ->
        return false

    trocarUsuario: () ->
        if @temAtividadesPendentes == true
           alert("Existem registros de atividades não enviados aos gerentes. Só é possivel trocar de usuário após enviar todos os registros pendentes.")
        else
            @storage.removeItem('Usuario')
            @usuario = null
            $.mobile.changePage('#pglogin',{changeHash:false})
           
    # Bind any events that are required on startup. Common events are:
    # 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: () ->
        document.addEventListener('deviceready', this.onDeviceReady, false)

    # The scope of 'this' is the event. In order to call the 'receivedEvent'
    # function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: () =>
        app.receivedEvent('deviceready')
        $("#loginForm").on "submit", (e) =>
            #disable the button so we can't resubmit while we wait
            $("#submitButton").attr("disabled","disabled")
            u = $("#username").val()
            p = $("#password").val()
            if(u and  p )
                url = "http://sav.wancharle.com.br/logar/"
                $.post(url, {username:u,password:p}, (res) =>
                        
                    if(res == true)
                        @setUsuario u
                        $.mobile.changePage("#pglogado",{changeHash:false})
                    else
                        alert("Usuário ou Senha inválidos!")
                    
                    $("#submitButton").removeAttr("disabled")
                ,"json")
            else
                $("#submitButton").removeAttr("disabled")
            return false

   
    # Update DOM on a Received Event
    receivedEvent: (id) ->
        if @usuario 
            $.mobile.changePage("#pglogado",{changeHash:false})
        console.log('Received Event: ' + id)

window.App = App
