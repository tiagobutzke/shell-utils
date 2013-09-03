#!/bin/bash
echo "---- Reading path ----"

for f in `ls $2 | grep \.sql`; do
    if [ -r $2$file ]; then
        echo "> Importing $f"

	cat $2$f |
	grep -v ' KEY "' | 
	grep -v ' UNIQUE KEY "' |
	grep -v ' PRIMARY KEY ' |
	sed -e '/^SET/d' |
	sed -e '/^USE `/d' | 
	sed -e '/^CREATE DATABASE/d' | 
	sed -e '/^LOCK TABLES/d' | 
	sed -e '/^UNLOCK/d' | 
	sed -e '/^begin;/d' | 
	sed -e '/^commit;/d' | 
	sed -e '/^(`last_activity`)/d' | 
	sed -e '/^UNIQUE KEY^/d' | 
	sed -e '/^KEY `/d' | 
	sed -e 's/.*ENGINE=.*/);/' | 
	sed -e 's/ unsigned / /g' |
	sed -e 's/ NOT NULL AUTO_INCREMENT/ primary key autoincrement/g' |
	sed -e 's/ AUTO_INCREMENT/ primary key autoincrement/g' |
	sed -e 's/ smallint([0-9]*) / integer /g' |
	sed -e 's/ bigint([0-9]*) / integer /g' | 
	sed -e 's/ tinyint([0-9]*) / integer /g' |
	sed -e 's/ int([0-9]*) / integer /g' |
	sed -e 's/ character set [^ ]* / /g' |
	sed -e 's/ enum([^)]*) / varchar(255) /g' |
	sed -e 's/ on update [^,]*//g' | 
	perl -e 'local $/;$_=<>;s/,\n\)/\n\)/gs;print "begin;\n";print;print "commit;\n"' |
	perl -pe '
            if (/^(INSERT.+?)\(/) {
     		$a=$1;
     		s/\\'\''/'\'\''/g;
     		s/\\n/\n/g;
	        s/\),\(/\);\n$a\(/g;
	  }
  	' > tmp
	
	cat tmp | sqlite3 $1 > $1.err

        ERRORS=`cat $1.err | wc -l`
        if [ $ERRORS == 0 ]; then
            echo "Conversion completed without error. Output file: $1"
            rm $1.err
	    rm tmp
        else
            echo "There were errors during conversion.  Please review $1.err and $1 for details."
        fi
    fi
done

`chmod 777 $1`
`chmod 777 $1.err`

echo ""
echo "DONE!"
echo ""
echo "##############################"
echo "#### Twitter @tiagobutzke ####"
echo "##############################"

exit
