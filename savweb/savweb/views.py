#!/usr/bin/env python
#-*- coding: utf-8 -*-

from django.contrib.auth import authenticate, login
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from .models import Professor, Atividade

import json
import datetime

@csrf_exempt
def logar(request):
    username = request.POST['username']
    password = request.POST['password']
    user = authenticate(username=username, password=password)
    if user is not None and user.is_active and user.professor_set.count() == 1:
        response_data = True
    else:
        response_data = False
    return HttpResponse(json.dumps(response_data), content_type="application/json")

@csrf_exempt
@transaction.atomic
def salvar(request):

    # sincroniza atividades do telefone
    json_s = request.POST['json']
    json_obj = json.loads(json_s)
    for o in json_obj:
        if o.get('realizada',False):
            id = int(o.get('id'))
            ativ = Atividade.objects.get(pk=id)
            ativ.realizada = True
            ativ.numero_de_presentes = int(o.get('numero_de_presentes',0))
            ativ.numero_de_participantes = int(o.get('numero_de_participantes',0))
            ativ.horario_inicio_registrado= datetime.datetime.strptime(o.get('h_inicio_registrado'),'%H:%M:%S')
            ativ.horario_fim_registrado= datetime.datetime.strptime(o.get('h_fim_registrado'),'%H:%M:%S')
            ativ.gps= o.get('gps','null')
            ativ.save()

    # carrega atinumero_de_presentesvidades pendentes do usuario
    p = Professor.objects.get(user__username=request.POST['usuario'])
    atividadesPendentes = p.atividade_set.filter(realizada=False).filter(data__gte=datetime.datetime.now().date())
    obj = []
    for a in atividadesPendentes:
        o = {}
        o['gerencia'] = a.gerencia
        o['tipo'] =a.tipo
        o['local']= a.local
        o['id']= a.id
        o['data']= a.data.strftime("%d/%m/%Y")
        o['usuario']= a.professor.user.username
        o['h_inicio']= a.horario_inicio.strftime("%H:%M:%S")
        o['h_fim']= a.horario_fim.strftime("%H:%M:%S")
        obj.append(o)

    #obj = [ {'gerencia':"RBC/ENE/JS", 'local':"EDMA", 'id':"1", 'usuario':"fabricia", 'data':"21/10/2014", 'h_inicio': "03:08:00", 'h_fim': "07:30:00", 'tipo': 'A' }]
    return HttpResponse(json.dumps(obj), content_type='application/json')

@csrf_exempt
def acompanhamento(request):
    json_objs = []
    for a in Atividade.objects.all():
        if not a.gps.startswith('null'):
            o= {}
            o['cat']=a.get_tipo_display()
            o['latitude'] = a.gps.split(',')[0]
            o['longitude'] = a.gps.split(',')[1]
            o['texto']= "<h3>{0}<h3><p>Usuario: {1}<br>Data: {2} de {3} as {4}</p>".format(a.identificacao, a.professor, a.data, a.horario_inicio, a.horario_fim)
            json_objs.append(o)
    
    if 'callback' in request.REQUEST:
        # a jsonp response!
        data = '%s(%s);' % (request.REQUEST['callback'], json.dumps(json_objs))
        return HttpResponse(data, "text/javascript")
    else:
        return HttpResponse(json.dumps(json_objs), content_type='application/json')



# vim: set ts=4 sw=4 sts=4 expandtab: 

