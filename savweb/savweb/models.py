#!/usr/bin/env python
#-*- coding: utf-8 -*-

from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError

class Professor(models.Model):
    user = models.ForeignKey(User)
    telefone = models.CharField(max_length=14)

    
class Atividade(models.Model):
    TIPO_EXPEDIENTE = 'EX'
    TIPO_ALMOCO = 'AL'
    TIPO_AULA = 'AU'
    TIPOS = ((TIPO_EXPEDIENTE, u"Expediente"), (TIPO_ALMOCO, u"Almoço"), (TIPO_AULA, u"Aula"))

    professor = models.ForeignKey(Professor)
    tipo  = models.CharField(max_length=2, choices= TIPOS)
    
    identificacao = models.CharField(max_length=50, verbose_name=u"identificação", help_text=u"identificação da atividade. Exemplo: codigo de atividade - nome da turma")
    numero_de_presentes = models.IntegerField(default=0,null=True,blank=True)
    numero_de_participantes = models.IntegerField(default=0,null=True, blank=True)

    data = models.DateField()
    horario_inicio = models.TimeField()
    horario_fim = models.TimeField()

    gps = models.CharField(max_length=30,help_text=u"Coordenadas do gps no formato <latitude, longitude>. Exemplo: -43.004579, 25.445676" )

    def clean(self):
        if self.tipo == Atividade.TIPO_AULA and  (self.numero_de_presentes == 0 or self.numero_de_participantes == 0):
            raise ValidationError(u"é preciso informar o numero de pessoas presentes e participantes da atividade")

        
# vim: set ts=4 sw=4 sts=4 expandtab: 

