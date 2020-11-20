# Wikipedia Labels and PageLinks Extraction

apt-get update
apt-get install -y wget

cd /work
mkdir -p tmp

echo "download"
# download latest articles dump
if [ ! -f dewiki-latest-pages-articles.xml  ] && [ ! -f dewiki-latest-pages-articles.xml.bz2 ]; then
    wget https://dumps.wikimedia.org/dewiki/latest/dewiki-latest-pages-articles.xml.bz2
fi

echo "bunzip"
if [ ! -f dewiki-latest-pages-articles.xml ]; then
    bunzip2 -k dewiki-latest-pages-articles.xml.bz2
fi
## alternatively use 'bzcat' instead of 'cat' in commands below

# - extract and process file so that each article link (indicated by [[) starts in a new line
# - remove each line not containing title, page or starting with [
# - strip ]] from end of line
cat dewiki-latest-pages-articles.xml | sed 's/\[\[/\n[[/g' | sed '/^    <title>\|^  <page>\|^\[/!d' | sed 's/\]\].*//g' > tmp/linewise.txt


# - select only lines containing a label (indicated by [[)
grep "^\[\[" tmp/linewise.txt > tmp/labels-raw.txt


# - remove unwanted links (e.g. referring to users, discussions, internal stuff, etc.)
# - sort and remove duplicate lines
# result is a list of all labels 
cat tmp/labels-raw.txt | sed '/([^()]*ame)/d' | sed '/\[\[.*:*Portal:/d' | sed '/\[\[.*:*Diskussion/d' | sed '/\[\[.*:*Benutzerin:/d'|  sed '/\[\[.*:*Wikipedia:/d' | sed '/\[\[.*:*Hilfe:/d' | sed '/\[\[.*:*commons:/d' | sed '/\[\[.*:*Commons:/d' | sed '/\[\[.*:*Benutzer:/d'  | sed '/\[\[.*:*user:/d' | sed '/\[\[.*:*User:/d'| sed '/\[\[.*:*Bild:/d' | sed '/\[\[.*:*Image:/d'  | sed '/\[\[.*:*WP:/d' | sed '/\[\[.*:*Wp:/d'  | sed '/\[\[.*:*Datei:/d'  | sed '/\[\[.*:*Diskussion:/d'  | sed '/\[\[.*:*File:/d'  | sed '/\[\[.*:*doi:/d' | sed '/\[\[.*:*Vorlage:/d' | sed '/\[\[.*:*Special:/d' | sed '/\[\[.*:*Spezial:/d' | sed '/\[\[.*:*Benutzer Diskussion:/d' | sed '/\[\[.*:*User talk:/d' | sed '/\[\[.:/d' | sed '/\[\[..:/d' | sed '/\[\[:..:/d' | sed 's/:Kategorie/Kategorie/g' | sed '/\[\[.*:*Liste /d' |  sed 's/\[\[//g'  | awk '{$1=$1;print}'  | LC_ALL=c sort -u  > tmp/labels_ws.txt


# - find lines with <title> (indicating the begin of an article) and 'memorize' the articles name for the further linewise processing
# - print the article name as well as the links the article contains
# - sort and remove duplicate lines
cat tmp/linewise.txt | awk '{$1=$1;print}' | awk '{if ( substr($1,0,8) == "<title>") { t = $0 } { print  t " " $0 }}' | sed 's/<title>//g' | sed 's/|.*//g' | awk '{$1=$1;print}'  | sort -u > tmp/links-raw.txt


# - remove unwanted items
# - sort and remove duplicate lines
# result is the list of wikipedia pagelinks
cat tmp/links-raw.txt| sed '/\[\[.*:*Portal:/d'  | sed '/\[\[.*:*Diskussion/d' | sed '/\[\[.*:*Benutzerin:/d'| sed '/\[\[.*:*Wikipedia:/d' | sed '/\[\[.*:*Portal:/d' | sed '/\[\[.*:*Hilfe:/d' | sed '/\[\[.*:*commons:/d' | sed '/\[\[.*:*Commons:/d' | sed '/\[\[.*:*Benutzer:/d'  | sed '/\[\[.*:*user:/d' | sed '/\[\[.*:*User:/d'| sed '/\[\[.*:*Bild:/d' | sed '/\[\[.*:*Image:/d'  | sed '/\[\[.*:*WP:/d' | sed '/\[\[.*:*Wp:/d'  | sed '/\[\[.*:*Datei:/d' | sed '/\[\[.*:*Diskussion:/d'  | sed '/\[\[.*:*File:/d'  | sed '/\[\[.*:*doi:/d' | sed '/\[\[.*:*Vorlage:/d' | sed '/\[\[.*:*Special:/d' | sed '/\[\[.*:*Spezial:/d' | sed '/\[\[.*:*Benutzer Diskussion:/d' | sed '/\[\[.*:*User talk:/d' | sed '/\[\[.:/d' | sed '/\[\[..:/d' | sed '/\[\[:..:/d' | sed 's/:Kategorie/Kategorie/g' |  sed '/<\/title>$/d' |  sed '/<page>$/d' | sed 's/<\/title>//g' | awk '{$1=$1;print}'  |  LC_ALL=c sort -u  > tmp/links_ws.txt


# - for indexing we need labels and links with underscore instead of whitespace, but whitespace separated
cat tmp/links_ws.txt | awk '{$1=$1;print}' | sed 's/ /_/g' | sed 's/_\[\[/ /g' | sort -u >  tmp/links.txt

cat tmp/labels_ws.txt| awk '{$1=$1;print}' | sed 's/ /_/g' | sed 's/|/ /g' | sort -u >  tmp/labels.txt


# extract redirects
# - find lines with a) '<redirect...' and lines with b) '<title>' 
# - select only consecutive lines  a) and b), strip whitespace
cat dewiki-latest-pages-articles.xml | grep '<redirect title\|<title>' | grep -B1 '<redirect' | awk '{$1=$1 ; print}' > tmp/redirects_ws.txt 

# - merge consecutive lines, remove '--' lines as well as XML tags, replace space with underscore, exchange columns
cat tmp/redirects_ws.txt | awk '{if ( substr($1,0,7) == "<title>") { t = $0 } else { print  t " " $0 }}' | grep -v "\-\-" |sed 's/<title>//g' |sed 's/ /_/g' |sed 's/<\/title>_<redirect_title="/ /g' |sed 's/"_\/>//g' | awk '{print $2 " " $1}' | sort -u > tmp/redirect_labels.txt

# - select second column, 'the actual redirect URIs' 
cat tmp/redirect_labels.txt | awk '{print $2}' | sort -u > tmp/redirects.txt


# - in the labels file, replace redirects with their targets 
join -v 2 tmp/redirects.txt tmp/labels.txt > tmp/labels_c.txt

# - add redirect entities as labels of their redirect target
cat tmp/labels_c.txt  tmp/redirect_labels.txt | awk '{$1=$1;print}' | sort -u > tmp/labels_r.txt

# - replace redirects in links
sort -k 2 -u tmp/redirect_labels.txt > tmp/redirect_labels_s2.txt
sort tmp/links.txt > tmp/links_s1.txt 
sort -k 2 tmp/links.txt > tmp/links_s2.txt 
join -1 2 tmp/redirect_labels_s2.txt tmp/links_s1.txt | awk '{print $2 " " $3 }' > tmp/links_left.txt
join -1 2 -2 2 tmp/redirect_labels_s2.txt tmp/links_s2.txt | awk '{print $3 " " $2 }' > tmp/links_right.txt

join -1 2 -v 2 tmp/redirect_labels_s2.txt tmp/links_s1.txt > tmp/outleft.txt
sort -k 2 tmp/outleft.txt > tmp/outleft_s2.txt
join -1 2 -2 2 -v 2 tmp/redirect_labels_s2.txt tmp/outleft_s2.txt | awk '{print $2 " " $1 }' > tmp/out.txt 
cat tmp/links_left.txt tmp/links_right.txt tmp/out.txt | awk '{$1=$1 ; print}' | sort -u > tmp/links_r.txt


#extract normdata
grep "<title\|{{Normdaten" dewiki-latest-pages-articles.xml |  grep -B1 "{{Normdaten" | awk '{$1=$1 ; print}' > tmp/norm_raw.txt 
cat tmp/norm_raw.txt | awk '{if ( substr($1,0,7) == "<title>") { t = $0 } else { print  t " " $0 }}' | grep -v "\-\-" |sed 's/<title>//g' |sed 's/ /_/g' |sed 's/<\/title>_{{Normdaten|/ /g' | sed 's/}}//g' > normdata.txt

grep 'TYP=p' normdata.txt | awk '{print $1}' > tmp/persons.txt
cat tmp/persons.txt |sed 's/_/ /' | awk '{print $1 "_" $2 " "  $2 "_" $1}' > tmp/reverse-persons.txt



# - extract disambiguation pages
cat dewiki-latest-pages-articles.xml | grep '{{Begriffsklärung}}\|<title>' | grep -B1 '{{Begriffsklärung}}' | awk '{$1=$1 ; print}' > tmp/disamb_ws.txt 
grep "<title>" tmp/disamb_ws.txt |sed 's/<title>//g' |sed 's/<\/title>//g' |sed 's/ /_/g'  |sort -u > tmp/disamb.txt

# - get the diambiguation labels
join tmp/disamb.txt tmp/labels_r.txt | grep " "  > tmp/disamb_labels.txt

# - remove disambs from labels
join -v 2 tmp/disamb.txt tmp/labels_r.txt  > tmp/labels_wn.txt

# - merge reverse person labels into labels (to also find 'Armstrong, Neil')
cat tmp/reverse-persons.txt tmp/labels_wn.txt | sort -u > tmp/labels_rp.txt

# - remove disambs from links, and remove self-links
join -v 2 tmp/disamb.txt tmp/links_r.txt | awk '{ if ($1!=$2)  print}' | LC_ALL=C sort -u > links.txt

# - just extract the first column of the pagelinks 
# - sort and remove duplicate lines
# result is the list of entities
cat links.txt |awk '{print $1}' | awk '{$1=$1; print}' | sort -u > entities.txt 

# join the existing entities with labels to remove 'dead labels' (from links to non-existing pages)
join entities.txt tmp/labels_rp.txt > labels.txt

# extract categories
grep "^Kategorie:" links.txt | grep " Kategorie:" > categories.txt

echo "cleaning up"
# remove tmp content
rm tmp/*
rmdir tmp
