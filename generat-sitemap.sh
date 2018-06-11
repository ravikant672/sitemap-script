#!bin/bash
## Author : Ravikant
pythonDir=/app/web/www.squareyards.ca/sitemap-ca/sitemap_gen
sitemapDir=/app/web/www.squareyards.ca/sitemap-ca/output
projDir=/app/web/www.squareyards.ca/public_html/webroot

if [ $# != 1 ];then
	echo "please pass arguments with script"
	echo "all|newdev|location"
	exit
fi

## Python script for sitemap generate from access log.
cd $pythonDir 
rm -f output/sitemap.xml ## Removing before generating new
sudo python sitemap_gen.py --config=ca-config.xml --testing &> /dev/null

##logrotate -- custom log
/usr/sbin/logrotate --force /app/web/www.squareyards.ca/sitemap-ca/logrotatefile ## After generating sitemap log file is rotated.
echo "custom log file rotated"
##

newdevlopment() {
	query="select concat('<url><loc>','https://www.squareyards.ca/',
Replace(Lower(prj.ProjectName),' ','-'),'/',prj.projectId,
'/project','</loc><changefreq>daily</changefreq><priority>0.8</priority></url>')as link
from ca_project prj;"
	touch $sitemapDir/sitemap-new-devlopment-temp.xml
	cat $sitemapDir/default.xml >> $sitemapDir/sitemap-new-devlopment-temp.xml
	mysql -h 13.228.13.218 -u sitemap -pw3lc0m3 sqyglobal --skip-column-names -e "${query}" >> $sitemapDir/sitemap-new-devlopment-temp.xml
	if [ $? != 0 ];then
		echo "DB connection Problem"
		rm -f $sitemapDir/sitemap-new-devlopment-temp.xml
		exit
	fi
	echo "</urlset>" >> $sitemapDir/sitemap-new-devlopment-temp.xml
	echo "REPLACING & with &amp; in sitemap-new-devlopment-temp.xml"
	sed -i s/"&"/"&amp;"/g $sitemapDir/sitemap-new-devlopment-temp.xml
	mv $sitemapDir/sitemap-new-devlopment-temp.xml $sitemapDir/sitemap-new-devlopment.xml
	echo "sitemap of new devlopment created"

}

## This section for new-devlopment sitemap. sitemap.xml is generated form accesslog file.
locationBased(){
	## Below code for random url generate -- location based search.
	n=0
	u=0
	a=0
	while read -r line ; do
	## 
	n=$((n+1))
	url="<url>$line<changefreq>daily</changefreq><priority>0.8</priority></url>"
	if grep -Fq "$line" sitemap-location.xml
	then
		u=$((u+1))
	else
		sed -i '/<\/urlset>/d' sitemap-location.xml
		echo "$url" >> sitemap-location.xml
		echo "</urlset>" >> sitemap-location.xml
		echo "New URL Added : $url"
		a=$((a+1))
		
	fi	
	done <<< "`grep -w "properties-for\|projects-in" $pythonDir/output/sitemap.xml | grep -v "?"`"
	echo "Location Total url found in log:$n"
	echo "Location Total url already exist: $u"
	echo "Location Total new url added: $a"
	echo "================================"
}



cd $sitemapDir
## For New Devlopment
if [ $1 == 'newdev' ];then
newdevlopment
fi
## For Location Based
if [ $1 == 'location' ];then
locationBased
fi
## For All
if [ $1 == "all" ];then
locationBased
newdevlopment
fi

## Copy .xml file in project dir.
rsync -avh $sitemapDir/ $projDir/  --exclude=default.xml --exclude=sitemap-new-devlopment-temp.xml 
echo "file sync in proj dir"
