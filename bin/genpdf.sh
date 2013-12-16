#!/bin/sh

typeset LOGFILE=~/Development/build/tmp/linux-sea-build/build.log;
typeset -i DONETWORK;
typeset -i DOPDF;

if [[ "${1}" = "-n" ]] || [[ "${2}" = "-n" ]];
then
  DONETWORK=1;
else
  DONETWORK=0;
fi

if [[ "${1}" = "-N" ]] || [[ "${2}" = "-N" ]];
then
  DOPDF=0;
else
  DOPDF=1;
fi
  

# Create temporary directory
echo -n "Creating temporary directory... ";
rm -rf ~/Development/build/tmp/linux-sea-build
mkdir ~/Development/build/tmp/linux-sea-build
cd ~/Development/build/tmp/linux-sea-build
echo "done";

# Copy over files
echo -n "Copying files... ";
cp -r ~/Development/Centralized/Linux-Sea/src/linux_sea* .
echo "done";

# Generate index
echo -n "Generating index file... ";
collateindex.pl -N -o genindex.sgm > ${LOGFILE} 2>&1;
#jade -t sgml -d /usr/share/sgml/docbook/dsssl-stylesheets-1.79/html/docbook.dsl -V html-index /usr/share/sgml/xml.dcl linux_sea.xml >> ${LOGFILE} 2>&1;
xsltproc --xinclude --param chunk.section.depth 0 --param use.id.as.filename 1 /usr/share/sgml/docbook/xsl-stylesheets/html/chunk.xsl linux_sea.xml >> ${LOGFILE} 2>&1;
collateindex.pl -o genindex.sgm HTML.index >> ${LOGFILE} 2>&1;
echo "done";

# Adding style information
echo -n "Adding style information... ";
cp ~/Development/Centralized/Linux-Sea/style.css .;
for F in *.html;
do
  sed -i -e 's:</head:<link type="text/css" rel="stylesheet" href="style.css" title="default" media="all" /><meta name="viewport" content="width=device-width", initial-scale=1.0" /></head:g' ${F};
done
echo "done";

# Fix oasis-open.org URLs 
echo -n "Fixing oasis-open.org link... ";
grep -v "oasis-open.org/docbook" index.html > T;
mv T index.html;
echo "done";

# Building OneHugeXML
echo -n "Generating the single-XML source... ";
xsltproc --xinclude ~/Development/Centralized/Linux-Sea/src/copy.xsl linux_sea.xml > linuxsea.xml;
xmllint --format linuxsea.xml > LINUXSEA.xml;
rm linuxsea.xml;
echo "done";

# Building the epub
echo -n "Building the ePub version... ";
mkdir linuxsea-epub;
xsltproc --stringparam base.dir linuxsea-epub/OEBPS/ /usr/share/sgml/docbook/xsl-stylesheets/epub3/chunk.xsl LINUXSEA.xml >> ${LOGFILE} 2>&1;
cp -r linux_sea/images linuxsea-epub/OEBPS;
cd linuxsea-epub;
zip -X0 linux_sea.epub mimetype >> ${LOGFILE} 2>&1;
zip -r -X9 linux_sea.epub META-INF OEBPS >> ${LOGFILE} 2>&1;
mv linux_sea.epub ../;
cd ..;
echo "done";

if [[ ${DOPDF} -eq 1 ]];
then
  # Building book
  echo -n "Building book PDF... ";
  xsltproc --output linux_sea.fo --stringparam paper.type A4 /usr/share/sgml/docbook/xsl-stylesheets/fo/docbook.xsl LINUXSEA.xml >> ${LOGFILE} 2>&1;
  fop linux_sea.fo linux_sea.pdf >> ${LOGFILE} 2>&1;
  echo "done";
fi

cp ~/Development/build/tmp/linux-sea-build/*.html ~/Sites/swift.siphos.be/linux_sea/;
cp ~/Development/build/tmp/linux-sea-build/*.css ~/Sites/swift.siphos.be/linux_sea/;
cp ~/Development/build/tmp/linux-sea-build/css.html ~/Sites/swift.siphos.be/linux_sea/;
cp ~/Development/build/tmp/linux-sea-build/images/* ~/Sites/swift.siphos.be/linux_sea/images/;
cp ~/Development/build/tmp/linux-sea-build/linux_sea.pdf ~/Sites/swift.siphos.be/linux_sea/;
cp ~/Development/build/tmp/linux-sea-build/linux_sea.epub ~/Sites/swift.siphos.be/linux_sea/;

echo "All files are moved into ~/Development/build/tmp/linux-sea-build and synchronised with the site local backup";
