#!/bin/bash
#
# gpkg_sql.sh
#
# Sentencias SQL para la generación de geopakages
#

declare -A sql_a

sql_a["m_municipalities"]="select \
b.idut idut, \
a.url_2d b5mcode, \
a.nombre_e name_eu, \
a.nombre_c name_es, \
b.codmuni codmuni, \
c.comarca region, \
a.tipo_e type_eu, \
a.tipo_c type_es, \
a.tipo_i type_en, \
b.polygon geom \
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.giputz b,b5mweb_nombres.n_municipios c
where a.url_2d='M_'||b.codmuni \
and b.codmuni=c.codmuni \
and a.id_nombre1<>'996'"

sql_a["d_postaladdresses"]="select \
b.idut idut, \
a.idnombre idname, \
'D_A'||idnombre b5mcode, \
a.codmuni codmuni, \
a.muni_e muni_eu, \
a.muni_c muni_es, \
a.codcalle codstreet, \
a.calle_e street_eu, \
a.calle_c street_es, \
a.noportal door_number, \
a.bis bis, \
decode(a.codpostal,' ',null,to_number(a.codpostal)) postal_code, \
a.distrito coddistr, \
a.seccion codsec, \
a.nomedif_e name_eu, \
a.nomedif_c name_es, \
'ERAIKINA' type_eu, \
'EDIFICIO' type_es, \
'BUILDING' type_en, \
b.polygon geom \
from b5mweb_nombres.solr_edifdirpos a,b5mweb_25830.a_edifind b,b5mweb_nombres.n_rel_area_dirpos c \
where a.idnombre=c.idpostal \
and c.idut=b.idut \
order by a.idnombre"
