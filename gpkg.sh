#!/bin/bash
#
# gpkg.sh
#
# Generación de Geopackages para los servicios de localización y consulta del b5m
#

# Variables de entorno
export ORACLE_HOME="/opt/oracle/instantclient"
export LD_LIBRARY_PATH="$ORACLE_HOME"
export PATH="/opt/miniconda3/bin:/opt/LAStools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/oracle/instantclient:/opt/bin:/snap/bin"
export HOME="/home/lidar"

# Tildes y eines
export NLS_LANG=.AL32UTF8
set NLS_LANG=.UTF8

# Variables
gpkgd1="/home/data/gpkg"
gpkgp1="/home5/GPKG"
gpkgp2="$gpkgd1"
dir="${HOME}/SCRIPTS/GPKG"
usu="b5mweb_25830"
pas="web+"
bd="bdet"
usud1a="juanmari"
usud1b="develop"
hosd1="b5mdev"
usup1="genasys"
hosp1="explogenamap"
usup2a="juanmari"
usup2b="live"
hosp2a="b5mlive1.gipuzkoa.eus"
hosp2b="b5mlive2.gipuzkoa.eus"
logd="${dir}/log"
crn="$(echo "$0" | gawk 'BEGIN{FS="/"}{print NF}')"
scr="$(echo "$0" | gawk 'BEGIN{FS="/"}{print $NF}')"
log="$(echo "$0" | gawk -v logd="$logd" -v dat="$(date '+%Y%m%d')" 'BEGIN{FS="/"}{split($NF,a,".");print logd"/"a[1]"_"dat".log"}')"
err="$(echo "$0" | gawk -v logd="$logd" -v dat="$(date '+%Y%m%d')" 'BEGIN{FS="/"}{split($NF,a,".");print logd"/"a[1]"_"dat"_err.csv"}')"
if [ ! -d "$logd" ]
then
	mkdir "$logd" 2> /dev/null
fi
rm "$log" 2> /dev/null
rm "$err" 2> /dev/null

# Variables descripción campos
des_c1="field_name,description_eu,description_es,description_en"
des_c2="field descriptions"

# Varibales tablas descargas
dwm_c1="\"id_dw\",\"b5mcode\",\"b5mcode2\",\"name_es\",\"name_eu\",\"name_en\",\"year\",\"path_dw\",\"type_dw\",\"type_file\",\"url_metadata\""
dwn_url1="https://b5m.gipuzkoa.eus"

# Dependencias
source "${dir}/gpkg_sql.sh"

# Funciones
function msg {
	# echo mensaje
	if [ $crn -le 2 ]
	then
		echo -e "$1"
	fi
	echo -e "$1" >> "$log"
}

function conx {
	# Conexión a servidores externos con comprobación de errores
	nc=10
	for c in $(seq 1 $nc)
	do
		a=`/usr/bin/${2} $1 <<-EOF2 2>&1 > /dev/null
		$3
		EOF2`
		b="$(echo "$a" | gawk 'END{print $1}')"
		if [ "$b" != "ssh_exchange_identification:" ] && [ "$b" != "Connection" ]
		then
			break
		fi
		if [ $c -eq $nc ] && { [ "$b" = "ssh_exchange_identification:" ] || [ "$b" = "Connection" ]; }
		then
				echo "Error $2 $1 #${3}# "
		else
				sleep 10
		fi
	done
}

function hacer_gpkg {
	# Tareas Oracle 1
	if [ "${or1_a["$nom"]}" != "" ]
	then
		sqlplus -s ${usu}/${pas}@${bd} <<-EOF2 > /dev/null
		${or1_a["$nom"]}

		exit;
		EOF2
	fi

	# Geopackage inicio
	t="GIPUTZ"
	rm "$fgpkg1" 2> /dev/null
	ogr2ogr -f "GPKG" -s_srs "EPSG:25830" -t_srs "EPSG:25830" -lco DESCRIPTION="${des_a["$nom"]}" "$fgpkg1" OCI:${usu}/${pas}@${bd}:${t} -nln "$nom" -sql "${sql_a["$nom"]}" > /dev/null

	# Renombrar campos
	clist="$(ogrinfo -al -so "$fgpkg1" | gawk '
	BEGIN {
		a=0
	}
	{
		if (a == 1) print substr($1, 1, length($1)-1)
		if ($1 == "Geometry") a=1
	}
	')"
	for c in $clist
	do
		c2="$(echo "$c" | gawk '{print tolower($0)}')"
		ogrinfo -dialect ogrsql -sql "alter table $nom rename column $c to ${c}999" "$fgpkg1" > /dev/null
		ogrinfo -dialect ogrsql -sql "alter table $nom rename column ${c}999 to $c2" "$fgpkg1" > /dev/null
	done

	# Crear índice
	ogrinfo -sql "create index ${nom}_idx1 on $nom (${idx_a["$nom"]})" "$fgpkg1" > /dev/null

	# Crear tabla con las descripciones de los campos
	ca0="$(ogrinfo -al -so $fgpkg1 $nom | gawk 'BEGIN{a=0;FS=":"}{if(match($0,"Geometry Column")!=0){a=1;getline};if(a==1){print $1}}')"
	IFS='#' read -a ca1 <<< "${der_a["$nom"]}"
	rm "$csv1" 2> /dev/null
	echo "$des_c1" > "$csv1"
	for ca2 in $ca0
	do
		for ca3 in "${ca1[@]}"
		do
			IFS='|' read -a ca4 <<< "$ca3"
			if [ "$ca2" = "${ca4[0]}" ]
			then
				echo $ca3 | sed 's/|/,/g' >> "$csv1"
			fi
		done
	done
	ca5="$(wc -l "$csv1" | gawk '{print $1}')"
	if [ $ca5 -gt 1 ]
	then
		ogr2ogr -f "GPKG" -update "$fgpkg1" "$csv1" -nln "${nom}_desc" -lco DESCRIPTION="$nom $des_c2"
	fi
	rm "$csv1" 2> /dev/null

	# Crear tablas de descargas
	if [ "${dwn_a["$nom"]}" = "1" ]
	then
		dwn_des="downloads"
		dwn_c2=`sqlplus -s ${usu}/${pas}@${bd} <<-EOF2 2> /dev/null
		set mark csv on

		select a.id_dw,b.code_dw,b.name_eu,b.name_es,b.name_en,a.year,replace(listagg(c.format_dir,';') within group (order by c.format_dir),'year',a.path_dw||'/'||a.year) path_dw,listagg(c.format_dw,';') within group (order by c.format_dw) format_dw,d.file_type_dw,a.url_metadata
		from b5mweb_nombres.dw_list a,b5mweb_nombres.dw_types b,b5mweb_nombres.dw_formats c,b5mweb_nombres.dw_file_types d,b5mweb_nombres.dw_rel_formats e
		where a.id_type=b.id_type
		and a.id_file_type=d.id_file_type
		and a.id_dw=e.id_dw
		and c.id_format=e.id_format
		group by a.id_dw,b.code_dw,b.name_eu,b.name_es,b.name_en,a.year,a.path_dw,d.file_type_dw,a.url_metadata
		order by a.year desc,b.code_dw desc;

		exit;
		EOF2`
		rm "$csv1" 2> /dev/null
		i=0
		for dwn_d in `echo "$dwn_c2"`
		do
			if [ $i -eq 0 ]
			then
				echo "$dwn_d" | gawk '
				{
					gsub("\"ID_DW\"", "\"ID_DW\",\"B5MCODE2\",\"DW_CAT\",\"YEAR\"")
					gsub("\"YEAR\",\"PATH_DW\",\"FORMAT_DW\",\"FILE_TYPE_DW\"", "\"SERIES_DW\"")
					gsub(",\"CODE_DW\"", "")
					gsub(",\"URL_METADATA\"", "")
					print tolower($0)
				}
				' > "$csv1"
				dwn_fields2=`gawk '
				{
					gsub("\"", "")
					gsub(",", ",b.")
					gsub("id_dw,", "")
					print $0
				}
				' "$csv1"`
				let i=$i+1
			else
				IFS=',' read -a dwn_e <<< "$dwn_d"
				dwn_dir1=`echo "${dwn_e[6]}" | sed s/\"//g`
				dwn_typ1=`echo "${dwn_e[7]}" | sed s/\"//g`
				IFS=';' read -a dwn_dir1_a <<< "$dwn_dir1"
				IFS=';' read -a dwn_typ1_a <<< "$dwn_typ1"
				dwn_typ2=`echo ${dwn_dir1_a[0]} | gawk 'BEGIN { FS = "/" } { split($NF, a, "_"); print a[2]}'`
				dwn_file_type=`echo "${dwn_e[8]}" | sed s/\"//g`
				dwn_file_type2=`echo "$dwn_file_type" | gawk '{ print tolower($0)}'`

				# Comprobando que haya el mismo numero de descargas disponibles en los distintos formatos
				num_a=0
				war_a=0
				if [ "${#dwn_dir1_a[@]}" -gt 1 ]
				then
					j=0
					for dwn_dir1_b in "${dwn_dir1_a[@]}"
					do
						num_b=`ls ${dwn_dir1_b}/*.${dwn_file_type2} | wc -l`
						if [ $j -eq 0 ]
						then
							num_a=$num_b
						else
							if [ $num_a -ne $num_b ]
							then
								war_a=1
							fi
							num_a=$num_b
						fi
						let j=$j+1
					done
				fi
				if [ $war_a -eq 1 ]
				then
					echo "\"${nom}\",${dwn_e[5]},\"$dwn_dir1\",\"número de ficheros diferente entre formatos\"" >> "$err"
				fi

				for dwn_f1 in `ls ${dwn_dir1_a[0]}/*.${dwn_file_type2}`
				do
					code_dw=`echo "$dwn_f1" | gawk 'BEGIN { FS = "/" } { split($NF, a, "_"); print a[2]}'`
					code_dw2=`echo "$dwn_f1" | gawk -v b="${dwn_e[1]}" 'BEGIN { FS = "/" } { gsub ("\"", "", b); split($NF, a, "_"); print b "_" a[1]}'`
					dw_year=`echo "${dwn_e[5]}" | sed s/\"//g`
					dw_metad=`echo "${dwn_e[9]}" | sed s/\"//g`
					#dwn_format="[ { 'b5mcode_dw': 'DW_${code_dw}_${code_dw2}', 'year': '${dw_year}', 'format': ["
					dwn_format="{ 'year': '${dw_year}', 'b5mcode_dw': 'DW_${code_dw}_${code_dw2}', 'format': ["
					j=0
					for dwn_dir1_i in "${dwn_dir1_a[@]}"
					do
						dwn_typ3=`echo "$dwn_dir1_i" | gawk 'BEGIN { FS = "/" } { split($NF, a, "_"); print a[2]}'`
						dwn_dir2_i=`echo "$dwn_dir1_i" | gawk 'BEGIN { FS="/" } { print $NF }'`
						dwn_f2=`echo "$dwn_f1" | gawk -v a="$dwn_typ2" -v b="$dwn_typ3" '{ gsub (a, b); print $0 }'`
						dwn_f3=`echo "$dwn_f2" | gawk 'BEGIN { FS="/" } { print $NF }'`
						dwn_url2="${dwn_url1}/${dwn_dir2_i}/${dwn_f3}"
						dwn_size_mb1=`ls -l ${dwn_f2} 2> /dev/null | gawk '{ printf "%.2f\n", $5 * 0.000001 }'`
						if [ "$dwn_size_mb1" = "" ]
						then
							echo "\"${nom}\",${dwn_e[5]},\"$dwn_f2\",\"no existe fichero\"" >> "$err"
						else
							dwn_format="${dwn_format} { 'format_dw': '${dwn_typ1_a[$j]}', 'url_dw': '${dwn_url2}', 'file_type_dw': '${dwn_file_type}', 'file_size_mb': $dwn_size_mb1 },"
						fi
						let j=$j+1
					done
					dwn_format=`echo "$dwn_format" | gawk '{ print substr($0, 1, length($0)-1) " ]" }'`
					dwn_format="${dwn_format}, 'url_metadata': '${dw_metad}'"
					dwn_format="${dwn_format} }"
					echo "${i},\"DW_${code_dw}\",${dwn_e[1]},${dwn_e[5]},${dwn_e[2]},${dwn_e[3]},${dwn_e[4]},\"${dwn_format}\"" >> "$csv1"
					let i=$i+1
				done
			fi
		done
		dwn_g="$(wc -l "$csv1" | gawk '{print $1}')"
		if [ $dwn_g -gt 1 ]
		then
			# Formateo del CSV
			rm "$csv2" 2> /dev/null
			#sort -t ":" -k "2,3" "$csv1" | gawk '
			sort -t, -k2,2 "$csv1" | gawk '
			{
				print $0
			}
			' > "$csv2"
			ogr2ogr -f "GPKG" -update "$fgpkg1" "$csv1" -nln "${nom}_asoc" -lco DESCRIPTION="$nom $dwn_des"
		fi
		#rm "$csv1" 2> /dev/null

		# Spatial Views
		# https://gdal.org/drivers/vector/gpkg.html
		ogr2ogr -f "GPKG" -update "$fgpkg1" -sql "create view ${nom}_view as select a.*,${dwn_fields2} from $nom a join ${nom}_asoc b on a.b5mcode = b.b5mcode2" "$fgpkg1"
		ogr2ogr -f "GPKG" -update "$fgpkg1" -sql "insert into gpkg_contents (table_name, identifier, data_type, srs_id) values ('${nom}_view', '${nom}_view', 'features', 25830)" "$fgpkg1"
		ogr2ogr -f "GPKG" -update "$fgpkg1" -sql "insert into gpkg_geometry_columns (table_name, column_name, geometry_type_name, srs_id, z, m) values ('${nom}_view', 'geom', 'GEOMETRY', 25830, 0, 0)" "$fgpkg1"
	fi

	# Copiar a destino
	ta01="rm \"/tmp/${tmp}\""
	tb01="$(conx "${usud1a}@${hosd1}" "ssh" "$ta01")"
	ta02="put \"$fgpkg1\" \"/tmp/${tmp}\""
	tb02="$(conx "${usud1a}@${hosd1}" "sftp" "$ta02")"
	ta03="cd \"$gpkgd1\";if [ -f \"/tmp/${tmp}\" ];then sudo rm \"$gpkg\";else exit;fi;sudo mv \"/tmp/${tmp}\" \"$gpkg\";sudo chown ${usud1b}:${usud1b} \"$gpkg\";rm \"/tmp/${tmp}\""
	tb03="$(conx "${usud1a}@${hosd1}" "ssh" "$ta03")"
	tbs01="${tb01}${tb02}${tb03}"
	if [ "$tbs01" != "" ]
	then
		msg " - $tbs01\c"
	fi
	# Geopackage fin

	# Oracle carga inicio
	# En el caso de las distancias entre municipios, provisonalmente
	# se hace la carga a Oracle ya que el rendimiento de la consulta
	# es mejor
	if [ "$nom" = "dm_distancemunicipalities" ]
	then
		sql_ora_a="${sql_a["$nom"]}"
		sql_ora_b="${sql_b["$nom"]}"
		sql_ora_c="${sql_c["$nom"]}"
		sql_ora="${sql_ora_b}${sql_ora_a};${sql_ora_c}"
		sqlplus -s ${usu}/${pas}@${bd} <<-EOF2 > /dev/null
		$sql_ora
		commit;

		exit;
		EOF2
	fi
	# Oracle carga fin

	# Tareas Oracle 2
	if [ "${or2_a["$nom"]}" != "" ]
	then
		sqlplus -s ${usu}/${pas}@${bd} <<-EOF2 > /dev/null
		${or2_a["$nom"]}

		exit;
		EOF2
	fi
}

function copiar_gpkg {
	# Copiar a producción 1
	#/usr/bin/ssh ${usup1}@${hosp1} <<-EOF1 > /dev/null 2> /dev/null
	#cd "$gpkgp1"
	#rm "$tmp"
	#EOF1
	#/usr/bin/sftp ${usup1}@${hosp1} <<-EOF1 > /dev/null 2> /dev/null
	#cd "$gpkgp1"
	#put "$fgpkg1" "$tmp"
	#EOF1
	#/usr/bin/ssh ${usup1}@${hosp1} <<-EOF1 > /dev/null 2> /dev/null
	#cd "$gpkgp1"
	#rm "$gpkg"
	#mv "$tmp" "$gpkg"
	#rm "$tmp"
	#EOF1
	ta04="cd \"$gpkgp1\";rm \"${tmp}\""
	tb04="$(conx "${usup1}@${hosp1}" "ssh" "$ta04")"
	ta05="put \"$fgpkg1\" \"${gpkgp1}/${tmp}\""
	tb05="$(conx "${usup1}@${hosp1}" "sftp" "$ta05")"
	ta06="cd \"$gpkgp1\";if [ -f \"${tmp}\" ];then rm \"$gpkg\";else exit;fi;mv \"${tmp}\" \"$gpkg\";rm \"${tmp}\""
	tb06="$(conx "${usup1}@${hosp1}" "ssh" "$ta06")"
	tbs02="${tb04}${tb05}${tb06}"
	if [ "$tbs02" != "" ]
	then
		msg " - $tbs02\c"
	fi

	# Copiar a producción 2
	hosp2_a=("$hosp2a" "$hosp2b")
	for hosp2 in "${hosp2_a[@]}"
	do
		ta07="rm \"/tmp/${tmp}\""
		tb07="$(conx "${usup2a}@${hosp2}" "ssh" "$ta07")"
		ta08="put \"$fgpkg1\" \"/tmp/${tmp}\""
		tb08="$(conx "${usup2a}@${hosp2}" "sftp" "$ta08")"
		ta09="cd \"$gpkgd1\";if [ -f \"/tmp/${tmp}\" ];then sudo rm \"$gpkg\";else exit;fi;sudo mv \"/tmp/${tmp}\" \"$gpkg\";sudo chown ${usup2b}:${usup2b} \"$gpkg\";rm \"/tmp/${tmp}\""
		tb09="$(conx "${usup2a}@${hosp2}" "ssh" "$ta09")"
		tbs03="${tb07}${tb08}${tb09}"
		if [ "$tbs03" != "" ]
		then
			msg " - $tbs03\c"
		fi
	done
}

function borrar_gpkg {
	# Borrar el gpkg temporal
	rm "$fgpkg1" 2> /dev/null
}

# Ver si existe el fichero de configuración
fconf="$(echo $0 | gawk 'BEGIN{FS=".";i=1}{while(i<NF){printf("%s.",$i);i++}}END{printf("dsv\n")}')"
if [ ! -f "$fconf" ]
then
        echo "No existe el fichero de configuración $fconf"
        exit 1
fi

# Inicio
ini="Inicio: $scr - $(date '+%Y-%m-%d %H:%M:%S')"
msg "$ini"
cd "$dir"

# Lectura del fichero de configuración
vconf="$(gawk '{t=substr($0,1,1);if((t=="1")||(t=="2")||(t=="3")){print $0}}' "$fconf")"
if [ "$vconf" != "" ]
then
	j="$(echo "$vconf" | wc -l)"
else
	j=0
fi
i=1
while read vconf2
do
	IFS='|' read -a aconf <<< "$vconf2"
	tip="${aconf[0]}"
	nom="${aconf[1]}"
	des="${aconf[2]}"
	fgpkg1="/tmp/${nom}.gpkg"
	gpkg="${nom}.gpkg"
	tmp="${nom}_tmp.gpkg"
	csv1="/tmp/${nom}_tmp1.csv"
	csv2="/tmp/${nom}_tmp2.csv"
	if [ $j -eq 0 ]
	then
		msg "0/${j}: $(date '+%Y-%m-%d %H:%M:%S') - No se hace nada"
	else
		msg "${i}/${j}: $(date '+%Y-%m-%d %H:%M:%S') - $nom - $des\c"
	fi
	if [ "$tip" = "1" ] || [ "$tip" = "2" ]
	then
		msg " - GPKG\c"
		hacer_gpkg
		msg " - ok\c"
	fi
	if [ "$tip" = "2" ] || [ "$tip" = "3" ]
	then
		msg " - PROD\c"
		copiar_gpkg
		msg " - ok\c"
	fi
	borrar_gpkg
	msg ""
	let i=$i+1
done <<-EOF
$vconf
EOF

msg ""
msg "$ini"
fin="Final:  $scr - $(date '+%Y-%m-%d %H:%M:%S')"
msg "$fin"

exit 0
