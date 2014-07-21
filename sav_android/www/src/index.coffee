
Storage.prototype.setObject = (key, value) ->
        this.setItem(key, JSON.stringify(value))


Storage.prototype.getObject = (key) ->
        value = this.getItem(key)
        return value and JSON.parse(value)

window.formatadata = (data) ->
    return data.getDate()+"/"+(parseInt(data.getMonth())+1)+'/'+data.getFullYear()


window.formatahora = (data) ->
    return data.getHours()+":"+data.getMinutes()+':'+data.getSeconds()

class window.Atividade
    @TIPO_AULA = 'AU' 
    @TIPO_ALMOCO = 'AL'
    @TIPO_EXPEDIENTE = 'EX'

    @estaAberta: ->
        expdata = window.localStorage.getItem('expediente_data')
        if expdata
            return true
        else
            return false
  
    @armazena: (id_de_remocao, usuario, tipo, identificacao,gps, ativdata, horario_inicio, horario_fim, numero_de_presentes, numero_de_participantes) ->
        atividades = window.localStorage.getObject('atividades')
        if not atividades
            atividades = new Array()

        atividade = {
            'usuario': usuario,
            'id': identificacao,
            'tipo': tipo,
            'data': ativdata,
            'h_inicio': horario_inicio,
            'h_fim': horario_fim,
            'gps': gps,
            'pendente': true,
            'time': (new Date()).getTime(),
            'numero_de_presentes': numero_de_presentes,
            'numero_de_participantes': numero_de_participantes
            }
        atividades.push(atividade)
        window.localStorage.setObject('atividades',atividades)
        window.localStorage.removeItem(id_de_remocao)
        Atividade.envia()

    @clearAtividadesPendentes: ()->
        atividades = new Array()
        for ativ in window.localStorage.getObject('atividades')
            if ativ['pendente']
                ativ['pendente']=false
            atividades.push(ativ)
        window.localStorage.setObject('atividades',atividades)
        
    @getAtividadesPendentes: () ->
        atividadesPendentes = new Array()
        atividades = window.localStorage.getObject('atividades')
        if not atividades
            return null
        for ativ in   atividades
            if ativ['pendente']
                atividadesPendentes.push(ativ)
        return atividadesPendentes

    @envia: () ->

        atividadesPendentes = Atividade.getAtividadesPendentes() 
        $.ajax({
            url: "http://sav.wancharle.com.br/registra_atividades/"
            type: 'POST',
            contentType: 'application/json',
            data: { json: JSON.stringify(atividadesPendentes)},
            dataType: 'json'
            }
        ).done((data)->
            if data == true
                window.localStorage.removeItem('atividadesPendentes')
        ).fail((error,textstatus)->
            alert('Não foi possível enviar os dados registrados ao servidor. Isso ocorre provavelmente por falta de conexão de dados no momento. Tente novamente quando tver um conexão de internet estável')
            console.log(textstatus)
        )
         

    
    constructor: (@tipo, identificacao ) ->
        @storage = window.localStorage
        if @tipo == 'AU'
           @identificacao = identificacao
        else if @tipo == 'AL'
           @identificacao = 'Almoço'
        else if @tipo == 'EX'
           @identificacao = 'Expediente'
   
        if Atividade.estaAberta()
            @load()
        else
            data_ativ = new Date()
            @data_atividade= formatadata(data_ativ)
            @horario_inicio = formatahora(data_avit)
            @gps = Expediente.gps
            @accuracy = Expediente.accuracy
            @time = (new Date()).getTime()
            @save()
            
    load: () ->
         @ativdata = @storage.getItem('atividade_data')
         @horario_inicio = @storage.getItem('atividade_horario_inicio')
         @gps = @storage.getItem('atividade_gps')
         @accuracy = @storage.getItem('atividade_accuracy')
         @time =parseInt( @storage.getTime('atividade_time'))
         return @expdata

    save: () ->
        @storage.setItem('atividade_data',@ativdata)
        @storage.setItem('atividade_horario_inicio',@horario_inicio)
        @storage.setItem('atividade_horario_gps',@gps)
        @storage.setItem('atividade_accuracy',@accuracy)
        @storage.setItem('atividade_time',@time)



class window.Expediente
    @tipo = "EX"
    @gps = null 
    @accuracy = 1000
    @estaAberto: ->
         expdata = window.localStorage.getItem('expediente_data')
         if expdata
            return true
         else
            return false

    constructor: (@usuario) ->
        @storage = window.localStorage
        expdata = @load()
        if not expdata
            expdata = new Date()
            @expdata = formatadata(expdata)
            @horario_inicio = formatahora(expdata)
            @save()
        Expediente.accuracy = 1000
        @iniciaWatch()

        $("#expuser").html(@usuario)
        $("#expdata").html(@expdata + " às "+ @horario_inicio)
       
    
    load: ()-> 
        if Expediente.estaAberto()
            @expdata = @storage.getItem('expediente_data')
            @horario_inicio = @storage.getItem('expediente_horario_inicio')
            Expediente.gps = @storage.getItem('expediente_gps')
            Expediente.accuracy = @storage.getItem('expediente_accuracy')
            return @expdata
        else
            return null

    save: ()->
        @storage.setItem('expediente_data',@expdata)
        @storage.setItem('expediente_horario_inicio',@horario_inicio)
        @storage.setItem('expediente_gps',Expediente.gps)
        @storage.setItem('expediente_accuracy',Expediente.accuracy)

    finalizar: ()->
        #TODO: checar se existe atividades abertas
        @horario_fim = formatahora(new Date())
        @storage.setItem('expediente_horario_fim',@horario_fim)

        Atividade.armazena('expediente_data',
           @usuario,
           Atividade.TIPO_EXPEDIENTE,
           'Expediente',
           Expediente.gps,
           @expdata,
           @horario_inicio,
           @horario_fim,
        )
        
        $.mobile.changePage('#pglogado',{changeHash:false})
        


    iniciaWatch: () =>
         @watchid = navigator.geolocation.watchPosition(
            (position) =>
                @watchSucess(position)
            ,(error) =>
                @watchError(error)
            ,{
                enableHighAccuracy: true
                timeout: 1*60*1000
            }
         )
    watchSucess: (position) ->
        if Expediente.accuracy > position.coords.accuracy
            Expediente.gps = position.coords.latitude+", "+position.coords.longitude   
            Expediente.accuracy = position.coords.accuracy 
            console.log("latlong: "+Expediente.gps + " accuracy:"+position.coords.accuracy)

    watchError: (error) ->
        if error.code == navigator.geolocation.PositionError.PERMISSION_DENIED
           alert("Para que o sistema funcione por favor ative o GPS do seu telefone")

        if error.code == navigator.geolocation.PositionError.POSITION_UNAVAILABLE
           alert("Não estou conseguindo obter uma posição do GPS, verifique se sua conexão GPS está ativa")

        if error.code == navigator.geolocation.PositionError.TIMEOUT
           console.log('timeout gps: ' + error.message)

class window.App
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

    iniciarExpediente: () ->
        @expediente = new Expediente(@usuario)
        $.mobile.changePage("#pgexpediente",{changeHash:false})

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
    atualizaUI: ()->
        # atualiza counter na pagina de logado
        atividadesPendentes = Atividade.getAtividadesPendentes()
        if atividadesPendentes
            html = "Atividades Recentes <span class='ui-li-count'>"+atividadesPendentes.length+"</span>"
            $('#logativrecent').html(html)
            $('#logulop').listview().listview('refresh') 

        # atualiza counter na pagina de expediente
        # atualiza pagina de atividades recentes

    receivedEvent: (id) ->
        if @usuario 
            @atualizaUI()
            if Expediente.estaAberto()
                @expediente = new Expediente(@usuario)
                $.mobile.changePage("#pgexpediente",{changeHash:false})
            else
                $.mobile.changePage("#pglogado",{changeHash:false})
        console.log('Received Event: ' + id)

