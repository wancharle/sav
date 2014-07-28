#!/usr/bin/env python
#-*- coding: utf-8 -*-


from django import forms
from django.contrib import admin
from .models import Professor, Atividade


class AtividadeAdmin(admin.ModelAdmin):
    date_hierarchy = 'data'
    list_display = ('identificacao', 'tipo', 'professor', 'data','horario_inicio', 'horario_fim', 'gps', 'numero_de_presentes', 'numero_de_participantes')
admin.site.register(Professor)
admin.site.register(Atividade,AtividadeAdmin)


# vim: set ts=4 sw=4 sts=4 expandtab: 

