# Wikipedia Labels and PageLinks Extraction

apt-get update
apt-get install -y wget

cd /work
mkdir -p tmp

echo "starting download"
# download latest articles dump
wget https://dumps.wikimedia.org/dewiki/latest/dewiki-latest-pages-articles.xml.bz2

echo "extracting 1 of 8"
# - extract and process file so that each article link (indicated by [[) starts in a new line
# - remove each line not containing title, page or starting with [
# - strip ]] from end of line
bzcat dewiki-latest-pages-articles.xml.bz2 | sed 's/\[\[/\n[[/g' | sed '/^    <title>\|^  <page>\|^\[/!d' | sed 's/\]\].*//g' > tmp/linewise.txt
							  
echo "extracting 2 of 8"
# - select only lines containing a label (indicated by [[)
grep "^\[\[" tmp/linewise.txt > tmp/labels-raw.txt

echo "extracting 3 of 8"
# - remove unwanted links (e.g. referring to users, discussions, internal stuff, etc.)
# - sort and remove duplicate lines
# result is a list of all labels 
cat tmp/labels-raw.txt | sed '/([^()]*ame)/d' | sed '/\[\[.*:*Portal:/d' | sed '/\[\[.*:*Diskussion/d' | sed '/\[\[.*:*Benutzerin:/d'|  sed '/\[\[.*:*Wikipedia:/d' | sed '/\[\[.*:*Hilfe:/d' | sed '/\[\[.*:*commons:/d' | sed '/\[\[.*:*Commons:/d' | sed '/\[\[.*:*Benutzer:/d'  | sed '/\[\[.*:*user:/d' | sed '/\[\[.*:*User:/d'| sed '/\[\[.*:*Bild:/d' | sed '/\[\[.*:*Image:/d'  | sed '/\[\[.*:*WP:/d' | sed '/\[\[.*:*Wp:/d'  | sed '/\[\[.*:*Datei:/d'  | sed '/\[\[.*:*Diskussion:/d'  | sed '/\[\[.*:*File:/d'  | sed '/\[\[.*:*doi:/d' | sed '/\[\[.*:*Vorlage:/d' | sed '/\[\[.*:*Special:/d' | sed '/\[\[.*:*Spezial:/d' | sed '/\[\[.*:*Benutzer Diskussion:/d' | sed '/\[\[.*:*User talk:/d' | sed '/\[\[.:/d' | sed '/\[\[..:/d' | sed '/\[\[:..:/d' | sed 's/:Kategorie/Kategorie/g' | sed '/\[\[.*:*Liste /d' |  sed 's/\[\[//g'  | awk '{$1=$1;print}'  | LC_ALL=c sort -u  > tmp/labels_ws.txt

echo "extracting 4 of 8"
# - find lines with <title> (indicating the begin of an article) and 'memorize' the articles name for the further linewise processing
# - print the article name as well as the links the article contains
# - sort and remove duplicate lines
cat tmp/linewise.txt | awk '{if ( substr($1,0,7) == "<title>") { t = $0 } { print  t " " $0 }}' | sed 's/<title>//g' | sed 's/|.*//g' | awk '{$1=$1;print}'  | sort -u > tmp/links-raw.txt

echo "extracting 5 of 8"
# - remove unwanted items
# - sort and remove duplicate lines
# result is the list of wikipedia pagelinks
cat tmp/links-raw.txt| sed '/\[\[.*:*Portal:/d'  | sed '/\[\[.*:*Diskussion/d' | sed '/\[\[.*:*Benutzerin:/d'| sed '/\[\[.*:*Wikipedia:/d' | sed '/\[\[.*:*Portal:/d' | sed '/\[\[.*:*Hilfe:/d' | sed '/\[\[.*:*commons:/d' | sed '/\[\[.*:*Commons:/d' | sed '/\[\[.*:*Benutzer:/d'  | sed '/\[\[.*:*user:/d' | sed '/\[\[.*:*User:/d'| sed '/\[\[.*:*Bild:/d' | sed '/\[\[.*:*Image:/d'  | sed '/\[\[.*:*WP:/d' | sed '/\[\[.*:*Wp:/d'  | sed '/\[\[.*:*Datei:/d' | sed '/\[\[.*:*Diskussion:/d'  | sed '/\[\[.*:*File:/d'  | sed '/\[\[.*:*doi:/d' | sed '/\[\[.*:*Vorlage:/d' | sed '/\[\[.*:*Special:/d' | sed '/\[\[.*:*Spezial:/d' | sed '/\[\[.*:*Benutzer Diskussion:/d' | sed '/\[\[.*:*User talk:/d' | sed '/\[\[.:/d' | sed '/\[\[..:/d' | sed '/\[\[:..:/d' | sed 's/:Kategorie/Kategorie/g' |  sed '/<\/title>$/d' |  sed '/<page>$/d' | sed 's/<\/title>//g' | awk '{$1=$1;print}'  |  LC_ALL=c sort -u  > tmp/links_ws.txt

echo "extracting 6 of 8"
# - just extract the first column of the pagelinks 
# - sort and remove duplicate lines
# result is the list of entities
cat tmp/links_ws.txt |awk '{FS="\\[\\["; print $1}' | awk '{$1=$1;print}'| sed 's/ /_/g' | sort -u > entities.txt 

echo "extracting 7 of 8"
# - for further processing we need labels and links with underscore instead of whitespace, but whitespace separated
cat tmp/links_ws.txt | awk '{print $0}' | sed 's/ /_/g' | sed 's/_\[\[/ /g' >  links.txt

echo "extracting 8 of 8"
cat tmp/labels_ws.txt| awk '{print $0}' | sed 's/ /_/g' | sed 's/|/ /g' >  labels.txt

echo "cleaning up"
# remove tmp content
rm tmp/*
rmdir tmp