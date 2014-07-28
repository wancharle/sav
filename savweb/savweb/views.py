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
    json_s = request.POST['json']
    json_obj = json.loads(json_s)
    for o in json_obj:
        if not o['usuario'].startswith('null'):
            p = Professor.objects.get(user__username=o['usuario'])
            a, created= Atividade.objects.get_or_create(professor=p, 
            tipo = o['tipo'],
            identificacao = o['id'],
            numero_de_presentes = int(o.get('numero_de_presentes',0)),
            numero_de_participantes = int(o.get('numero_de_participantes',0)),
            data = datetime.datetime.strptime(o.get('data'),'%d/%m/%Y'),
            horario_inicio= datetime.datetime.strptime(o.get('h_inicio'),'%H:%M:%S'),
            horario_fim= datetime.datetime.strptime(o.get('h_inicio'),'%H:%M:%S'),
            gps= o.get('gps','null')
            )
            a.save()

            

    return HttpResponse(json.dumps(True), content_type='application/json')

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

