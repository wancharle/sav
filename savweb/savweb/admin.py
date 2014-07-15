#!/usr/bin/env python
#-*- coding: utf-8 -*-


from django import forms
from django.contrib import admin
from .models import Professor, Atividade

admin.site.register(Professor)
admin.site.register(Atividade)


# vim: set ts=4 sw=4 sts=4 expandtab: 

