from django.conf.urls import patterns, include, url
from django.views.generic import TemplateView
from django.contrib import admin
from .views import logar, salvar, acompanhamento
admin.autodiscover()

urlpatterns = patterns('',
    url(r'^$', TemplateView.as_view(template_name='savweb/index.html'), name='home'),
    url(r'^mapa/', TemplateView.as_view(template_name='savweb/mapa.html'), name='home'),
    url(r'^logar/$',logar, name="logar"),
    url(r'^salvar/$',salvar, name="salvar"),
    url(r'^acompanhamento/$',acompanhamento, name="acompanhamento"),
    url(r'^admin/', include(admin.site.urls)),
)
