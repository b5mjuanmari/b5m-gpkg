#!/bin/bash
#
# gpkg_sql.sh
#
# Sentencias SQL para la generación de geopakages
#

declare -A des_a
declare -A sql_a
declare -A idx_a
declare -A der_a

# 1. m_municipalities (municipios) (carga: 19")
des_a["m_municipalities"]="Udalerria / Municipio / Municipality"
sql_a["m_municipalities"]="select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
decode(b.idnomcomarca,null,null,'S_'||b.idnomcomarca) b5mcode_others_s,
e.nombre_e b5mcode_others_s_name_eu,
e.nombre_c b5mcode_others_s_name_es,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.giputz b,b5mweb_nombres.n_municipios c,b5mweb_nombres.solr_gen_toponimia_2d d,b5mweb_nombres.solr_gen_toponimia_2d e
where a.url_2d='M_'||b.codmuni
and b.codmuni=c.codmuni
and e.url_2d='S_'||b.idnomcomarca
and to_char(b.idnomcomarca)=d.id_nombre1(+)
group by (a.url_2d,b.codmuni,a.nombre_e,a.nombre_c,d.nombre_e,d.nombre_c,a.tipo_e,a.tipo_c,a.tipo_i,b.idnomcomarca,e.nombre_e,e.nombre_c)"
idx_a["m_municipalities"]="b5mcode"
der_a["m_municipalities"]="b5mcode|B5m kodea|Código b5m|B5m code#\
name_eu|Udalerriaren izen ofiziala euskaraz|Nombre oficial del municipio en euskera|Official name of the municipality in Basque#\
name_es|Udalerriaren izen ofiziala gaztelaniaz|Nombre oficial del municipio en castellano|Official name of the municipality in Spanish#\
b5mcode_region|Eskualdearen b5m kodea|Código b5m de la comarca|Code b5m of the region#\
region_eu|Eskualdearen izena euskaraz|Nombre de la comarca en euskera|Name of the region in Basque#\
region_es|Eskualdearen izena gaztelaniaz|Nombre de la comarca en castellano|Name of the region in Spanish#\
type_eu|Elementu geografikoaren mota euskaraz|Tipo del elemento geográfico en euskera|Type of the geographic feature in Basque#\
type_es|Elementu geografikoaren mota gaztelaniaz|Tipo del elemento geográfico en castellano|Type of the geographic feature in Spanish#\
type_en|Elementu geografikoaren mota ingelesez|Tipo del elemento geográfico en inglés|Type of the geographic feature in English"

# 2. s_regions (comarcas) (carga: 36")
des_a["s_regions"]="Eskualdea / Comarca / Region"
sql_a["s_regions"]="select
a.url_2d b5mcode,
b.idnomcomarca b5mcode_region,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
'region' type_en,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.giputz b
where a.url_2d='S_'||b.idnomcomarca
group by (a.url_2d,b.idnomcomarca,a.nombre_e,a.nombre_c,a.tipo_e,a.tipo_c)"
idx_a["s_regions"]="b5mcode"

# 3. d_postaladdresses (direcciones postales) (carga: 1'07")
des_a["d_postaladdresses"]="Posta helbidea / Dirección postal / Postal Address"
sql_a["d_postaladdresses"]="select
a.idnombre idname,
'D_A'||a.idnombre b5mcode,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.municipio_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.municipio_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c),' - , ',',') name_es,
a.codmuni codmuni,
a.municipio_e muni_eu,
a.municipio_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.cp,' ',null,to_number(a.cp)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_builidng_eu,
a.nomedif_e name_builidng_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_edifdirpos_2d a,b5mweb_25830.a_edifind b,b5mweb_nombres.n_rel_area_dirpos c
where a.idnombre=c.idpostal
and c.idut=b.idut
group by (a.idnombre,a.idnombre,a.nomedif_e,a.nomedif_e,a.codmuni,a.municipio_e,a.municipio_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.cp,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)
union all
select
a.idnombre idname,
'D_A'||a.idnombre b5mcode,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.municipio_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.municipio_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c),' - , ',',') name_es,
a.codmuni codmuni,
a.municipio_e muni_eu,
a.municipio_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.cp,' ',null,to_number(a.cp)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_builidng_eu,
a.nomedif_e name_builidng_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_edifdirpos_2d a,b5mweb_25830.o_edifind b,b5mweb_nombres.n_rel_area_dirpos c
where a.idnombre=c.idpostal
and c.idut=b.idut
and a.idnombre not in (
select z.idpostal
from b5mweb_25830.a_edifind y,b5mweb_nombres.n_rel_area_dirpos z
where y.idut=z.idut
)
group by (a.idnombre,a.idnombre,a.nomedif_e,a.nomedif_e,a.codmuni,a.municipio_e,a.municipio_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.cp,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)
union all
select
a.idnombre idname,
'D_A'||a.idnombre b5mcode,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.municipio_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.municipio_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.municipio_c),' - , ',',') name_es,
a.codmuni codmuni,
a.municipio_e muni_eu,
a.municipio_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.cp,' ',null,to_number(a.cp)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_builidng_eu,
a.nomedif_e name_builidng_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_edifdirpos_2d a,b5mweb_25830.s_edifind b,b5mweb_nombres.n_rel_area_dirpos c
where a.idnombre=c.idpostal
and c.idut=b.idut
and a.idnombre not in (
select z.idpostal
from b5mweb_25830.a_edifind y,b5mweb_nombres.n_rel_area_dirpos z
where y.idut=z.idut
)
group by (a.idnombre,a.idnombre,a.nomedif_e,a.nomedif_e,a.codmuni,a.municipio_e,a.municipio_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.cp,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)"
idx_a["d_postaladdresses"]="b5mcode"

# 4. e_buildings (Edficios) (carga: 1'08")
des_a["e_buildings"]="Eraikina / Edficio / Building"
sql_a["e_buildings"]="select
a.idut idname,
'E_A'||a.idut b5mcode,
decode(a.idpostal, 0, null, 'D_A'||a.idpostal) b5mcode2,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.muni_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.muni_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c),' - , ',',') name_es,
a.codmuni codmuni,
a.muni_e muni_eu,
a.muni_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.codpostal,' ',null,to_number(a.codpostal)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_building_eu,
a.nomedif_e name_building_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.n_edifgen a,b5mweb_25830.a_edifind b
where a.idut=b.idut
group by (a.idut,a.idut,a.idpostal,a.nomedif_e,a.nomedif_e,a.codmuni,a.muni_e,a.muni_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.codpostal,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)
union all
select
a.idut idname,
'E_A'||a.idut b5mcode,
decode(a.idpostal, 0, null, 'D_A'||a.idpostal) b5mcode2,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.muni_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.muni_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c),' - , ',',') name_es,
a.codmuni codmuni,
a.muni_e muni_eu,
a.muni_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.codpostal,' ',null,to_number(a.codpostal)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_building_eu,
a.nomedif_e name_building_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.n_edifgen a,b5mweb_25830.o_edifind b
where a.idut=b.idut
group by (a.idut,a.idut,a.idpostal,a.nomedif_e,a.nomedif_e,a.codmuni,a.muni_e,a.muni_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.codpostal,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)
union all
select
a.idut idname,
'E_A'||a.idut b5mcode,
decode(a.idpostal, 0, null, 'D_A'||a.idpostal) b5mcode2,
replace(decode(a.nomedif_e,null,a.calle_e||', '||a.noportal||' '||a.muni_e,a.nomedif_e||' - '||a.calle_e||', '||a.noportal||' '||a.muni_e),' - , ',',') name_eu,
replace(decode(a.nomedif_e,null,decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c,a.nomedif_e||' - '||decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c)||', '||a.noportal||' '||a.muni_c),' - , ',',') name_es,
a.codmuni codmuni,
a.muni_e muni_eu,
a.muni_c muni_es,
a.codcalle codstreet,
a.calle_e street_eu,
decode(regexp_replace(a.calle_c,'[^,]+'),',',upper(substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),1,1))||''||substr(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' '),2,length(ltrim(regexp_substr(a.calle_c,'[^,]+',1,2),' ')))||' '||regexp_substr(a.calle_c,'[^,]+',1,1),a.calle_c) street_es,
a.noportal door_number,
a.bis bis,
decode(a.codpostal,' ',null,to_number(a.codpostal)) postal_code,
a.distrito coddistr,
a.seccion codsec,
a.nomedif_e name_building_eu,
a.nomedif_e name_building_es,
'1' official,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.n_edifgen a,b5mweb_25830.s_edifind b
where a.idut=b.idut
group by (a.idut,a.idut,a.idpostal,a.nomedif_e,a.nomedif_e,a.codmuni,a.muni_e,a.muni_c,a.codcalle,a.calle_e,a.calle_c,a.noportal,a.bis,a.codpostal,a.distrito,a.seccion,a.nomedif_e,a.nomedif_c)"
idx_a["e_buildings"]="b5mcode"

# 5. c_basins (cuencas) (carga: 17")
des_a["c_basins"]="Arroa / Cuenca / Basin"
sql_a["c_basins"]="select
a.url_2d b5mcode,
b.idnombre b5mcode_basin,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
'M_'||replace(a.codmunis,',','|M_') b5mcode_others_m,
replace(a.muni_e,',','|') b5mcode_others_m_name_eu,
replace(a.muni_c,',','|') b5mcode_others_m_name_es,
b.polygon geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.cuencap b
where a.url_2d='C_A'||b.idnombre"
idx_a["c_basins"]="b5mcode"

# 6. i_hydrography (hidrografía) (carga: 48")
des_a["i_hydrography"]="Hidrografia / Hidrografía / Hydrography"
sql_a["i_hydrography"]="select
a.id_topo idtopo,
a.id_nombre1 idname,
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
'C_A'||b.idnomcuenca b5mcode_others_c,
b.cuenca_e b5mcode_others_c_name_eu,
b.cuenca_c b5mcode_others_c_name_es,
'M_'||replace(a.codmunis,',','|M_') b5mcode_others_m,
replace(a.muni_e,',','|') b5mcode_others_m_name_eu,
replace(a.muni_c,',','|') b5mcode_others_m_name_es,
sdo_aggr_concat_lines(b.polyline) geom
from b5mweb_nombres.solr_gen_toponimia_2d a, b5mweb_25830.ibaiak b
where a.id_nombre1=to_char(b.idnombre)
group by(a.id_topo,a.id_nombre1,a.url_2d,a.nombre_e,a.nombre_c,b.idnomcuenca,b.cuenca_e,b.cuenca_c,a.tipo_e,a.tipo_c,a.tipo_i,a.codmunis,a.muni_e,a.muni_c)"
idx_a["i_hydrography"]="b5mcode"

# 7. z_districts (barrios y/o nombres urbanos) (carga: 16")
des_a["z_districts"]="Auzo eta/edo hiri izena / Barrio y/o nombre urbano / District and/or urban name"
sql_a["z_districts"]="select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'0' official,
'M_'||replace(a.codmunis,',','|M_') b5mcode_others_m,
replace(a.muni_e,',','|') b5mcode_others_m_name_eu,
replace(a.muni_c,',','|') b5mcode_others_m_name_es,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.barrioind b,b5mweb_nombres.b_barrios c
where a.id_nombre1=c.idnombre
and b.idut=c.idut
and a.url_2d like 'Z_%'
group by (a.url_2d,a.nombre_e,a.nombre_c,a.tipo_e,a.tipo_c,a.tipo_i,a.codmunis,a.muni_e,a.muni_c)"
idx_a["z_districts"]="b5mcode"

# 8. g_orography (toponimia de la orografía) (carga: 14")
des_a["g_orography"]="Orografiaren toponimia / Toponimia de la orografía / Toponymy of the orography"
sql_a["g_orography"]="select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'0' official,
'M_'||replace(a.codmunis,',','|M_') b5mcode_others_m,
replace(a.muni_e,',','|') b5mcode_others_m_name_eu,
replace(a.muni_c,',','|') b5mcode_others_m_name_es,
sdo_aggr_union(sdoaggrtype(b.polygon,0.005)) geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.montesind b,b5mweb_nombres.o_orograf c
where a.id_nombre1=c.idnombre
and b.idut=c.idut
and a.url_2d like 'G_%'
group by (a.url_2d,a.nombre_e,a.nombre_c,a.tipo_e,a.tipo_c,a.tipo_i,a.codmunis,a.muni_e,a.muni_c)"
idx_a["g_orography"]="b5mcode"

# 9. r_grid (cuadrículas, pauta) (carga: 10")
des_a["r_grid"]="Lauki-sarea / Cuadrícula / Grid"
sql_a["r_grid"]="select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec1 b
where a.nombre_e=b.tag
and a.tipo_e='1x1 km'
and a.url_2d like 'R_%'
union all
select
substr(a.url_2d,1,4)||lower(substr(a.url_2d,5,1)) b5mcode,
substr(a.nombre_e,1,2)||lower(substr(a.nombre_e,3,1)) name_eu,
substr(a.nombre_c,1,2)||lower(substr(a.nombre_c,3,1)) name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec2 b
where a.nombre_e=b.tag
and a.tipo_e='2x2 km'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec5 b
where a.nombre_e=b.tag
and a.tipo_e='5x5 km'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec b
where a.nombre_e=b.tag
and a.tipo_e='10x10 km'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.pauta5 b
where a.nombre_e=b.tag
and a.tipo_e='1:5000'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.pauta10 b
where a.nombre_e=b.tag
and a.tipo_e='1:10000'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.pauta25 b
where a.nombre_e=b.tag
and a.tipo_e='1:25000'
and a.url_2d like 'R_%'
union all
select
a.url_2d b5mcode,
a.nombre_e name_eu,
a.nombre_c name_es,
a.tipo_e type_eu,
a.tipo_c type_es,
a.tipo_i type_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.pauta50 b
where a.nombre_e=b.tag
and a.tipo_e='1:50000'
and a.url_2d like 'R_%'"
idx_a["r_grid"]="b5mcode"

# 10. dw_download (descargas) (carga: 2'30")
des_a["dw_download"]="Deskargak / Descargas / Downloads"
sql_a["dw_download"]="@@_5@@select
replace(a.url_2d,'R_','DW_') b5mcode,
a.nombre_e name_grid_eu,
a.nombre_c name_grid_es,
a.tipo_e type_grid_eu,
a.tipo_c type_grid_es,
a.tipo_i type_grid_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec5 b
where a.nombre_e=b.tag
and a.tipo_e='5x5 km'
and a.url_2d like 'R_%'
#
@@_1@@select
replace(a.url_2d,'R_','DW_') b5mcode,
a.nombre_e name_grid_eu,
a.nombre_c name_grid_es,
a.tipo_e type_grid_eu,
a.tipo_c type_grid_es,
a.tipo_i type_grid_en,
'1' official,
b.geom
from b5mweb_nombres.solr_gen_toponimia_2d a,b5mweb_25830.gipurec1 b
where a.nombre_e=b.tag
and a.tipo_e='1x1 km'
and a.url_2d like 'R_%'"
idx_a["dw_download"]="b5mcode"

# 11. sg_geodeticbenchmarks (señales geodésicas) (carga: 27")
sg_aju_eu="Doikuntza geodesikoa"
sg_sen_eu="Seinale geodesikoa"
sg_aju_es="Ajuste geodésico"
sg_sen_es="Señal geodésica"
sg_aju_en="Geodetic Adjustment"
sg_sen_en="Geodetic Benchmark"
sg_url="https://b5m.gipuzkoa.eus/geodesia/pdf"
des_a["sg_geodeticbenchmarks"]="Seinale geodesikoa / Señal geodésica / Geodetic Benchmark"
sql_a["sg_geodeticbenchmarks"]="select
'SG_'||a.pgeod_id b5mcode,
a.pgeod_id idgeodb,
a.nombre name_eu,
a.nombre name_es,
decode(a.ajuste,1,'${sg_aju_eu}','${sg_sen_eu}') type_eu,
decode(a.ajuste,1,'${sg_aju_es}','${sg_sen_es}') type_es,
decode(a.ajuste,1,'${sg_aju_en}','${sg_sen_en}') type_en,
'${sg_url}/'||a.archivo link,
a.file_type,
a.size_kb,
'1' official,
'M_'||a.codmuni b5mcode_others_m,
trim(regexp_substr(b.municipio,'[^/]+',1,1)) b5mcode_others_m_name_eu,
decode(trim(regexp_substr(b.municipio,'[^/]+',1,2)),null,b.municipio,trim(regexp_substr(b.municipio,'[^/]+',1,2))) b5mcode_others_m_name_es,
a.geom
from o_mw_bta.puntogeodesicobta a,b5mweb_nombres.n_municipios b
where a.codmuni=b.codmuni
and a.visible_web=1
order by a.pgeod_id"
idx_a["sg_geodeticbenchmarks"]="b5mcode"

# 12. dm_distancemunicipalities (distancia entre municipios) (carga: 1h12')
des_a["dm_distancemunicipalities"]="Udalerrien arteko distantzia / Distancia entre municipios / Distance Between Municipalities"
sql_a["dm_distancemunicipalities"]="select
c.idut iddm,
'DM_'||a.codmuni||'_'||b.codmuni b5mcode,
a.codmuni codmuni1,
a.muni_eu muni1_eu,
a.muni_es muni1_es,
a.muni_fr muni1_fr,
decode(a.ter_eu,'Gipuzkoa','001','Araba','002','Bizkaia','003','Nafarroa','004','005') codterm1,
a.ter_eu term1_eu,
a.ter_es term1_es,
a.ter_fr term1_fr,
a.id_area id_area1,
b.codmuni codmuni2,
b.muni_eu muni2_eu,
b.muni_es muni2_es,
b.muni_fr muni2_fr,
decode(b.ter_eu,'Gipuzkoa','001','Araba','002','Bizkaia','003','Nafarroa','004','005') codterm2,
b.ter_eu term2_eu,
b.ter_es term2_es,
b.ter_fr term2_fr,
b.id_area id_area2,
c.dist_r,
c.dist_c,
c.fecha dm_date,
'1' official,
c.geom
from mapas_otros.dist_ayunta2_muni a,mapas_otros.dist_ayunta2_muni b,mapas_otros.dist_ayunta2 c
where a.codmuni=c.codmuni1
and b.codmuni=c.codmuni2"
idx_a["dm_distancemunicipalities"]="b5mcode"
tabdm='gi_dm_distancem'
tabDM="$(echo "$tabdm" | gawk '{print toupper($1)}')"
tabdm2="dist_ayunta2"
tabDM2="$(echo "$tabdm2" | gawk '{print toupper($1)}')"
sql_b["dm_distancemunicipalities"]="drop table ${tabdm};
delete from
user_sdo_geom_metadata
where lower(table_name)='${tabdm}'
and column_name='GEOM';
create table ${tabdm}(
iddm number,
b5mcode varchar2(12),
codmuni1 varchar2(4),
muni1_eu varchar2(100),
muni1_es varchar2(100),
muni1_fr varchar2(100),
codterm1 varchar2(3),
term1_eu varchar2(100),
term1_es varchar2(100),
term1_fr varchar2(100),
id_area1 number,
codmuni2 varchar2(4),
muni2_eu varchar2(100),
muni2_es varchar2(100),
muni2_fr varchar2(100),
codterm2 varchar2(3),
term2_eu varchar2(100),
term2_es varchar2(100),
term2_fr varchar2(100),
id_area2 number,
dist_r number,
dist_c number,
dm_date date,
official number,
geom sdo_geometry,
constraint ${tabdm}_pk primary key(iddm)
);
insert into user_sdo_geom_metadata
select '${tabDM}',column_name,diminfo,srid
from all_sdo_geom_metadata
where table_name='${tabDM2}'
and column_name='GEOM';
insert into ${tabdm}(iddm,b5mcode,codmuni1,muni1_eu,muni1_es,muni1_fr,codterm1,term1_eu,term1_es,term1_fr,id_area1,codmuni2,muni2_eu,muni2_es,muni2_fr,codterm2,term2_eu,term2_es,term2_fr,id_area2,dist_r,dist_c,dm_date,official,geom)
"
sql_c["dm_distancemunicipalities"]="
create unique index ${tabdm}_idx on ${tabdm}(b5mcode,codmuni1,muni1_eu,muni1_es,codmuni2,muni2_eu,muni2_es);
create index ${tabdm}2_idx on ${tabdm}(codterm1,term1_eu,term1_es,codterm2,term2_eu,term2_es);
create index ${tabdm}_gidx
on ${tabdm}(geom)
indextype is mdsys.spatial_index
parameters('layer_gtype=MULTILINE');"

# 13. q_municipalcartography (cartografía municipal) (carga: 24")
des_a["q_municipalcartography"]="Udal kartografiaren inbentarioa / Inventario de cartografía municipal / Municipal Cartography Inventory"
sql_a["q_municipalcartography"]="select
a.id_levan,
'Q_' || a.id_levan b5mcode,
replace(a.nombre,'\"','') name_eu,
replace(a.nombre,'\"','') name_es,
a.propietario propietario_eu,
a.propietario propietario_es,
a.escala escala,
to_char(a.f_digitalizacion,'YYYY-MM-DD') f_digitalizacion,
to_char(a.f_levanoriginal,'YYYY-MM-DD') f_levanoriginal,
to_char(a.f_ultactua,'YYYY-MM-DD') f_ultactua,
a.empresa empresa,
'https://b5m.gipuzkoa.eus/map-2022/eu/Q_' || a.id_levan map_link_eu,
'https://b5m.gipuzkoa.eus/map-2022/es/Q_' || a.id_levan map_link_es,
'1' official,
'M_'||b.codmuni b5mcode_others_m,
trim(regexp_substr(c.municipio,'[^/]+',1,1)) b5mcode_others_m_name_eu,
decode(trim(regexp_substr(c.municipio,'[^/]+',1,2)),null,c.municipio,trim(regexp_substr(c.municipio,'[^/]+',1,2))) b5mcode_others_m_name_es,
d.polygon geom
from b5mweb_nombres.g_levancarto a,b5mweb_nombres.g_rel_muni_levan b,b5mweb_nombres.n_municipios c,b5mweb_25830.cardigind d
where a.tag=b.tag
and b.codmuni=c.codmuni
and a.tag=d.tag"
idx_a["q_municipalcartography"]="b5mcode"
