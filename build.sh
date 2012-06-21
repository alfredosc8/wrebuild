#!/bin/bash

#wre help
wrehelp() {
cat <<_WREHELP
 \`build.sh' builds the WebGUI Runtime Environment.
  
  Usage: $0 [OPTIONS] [PACKAGES]

  Build switches cause only select applications to build.
  They can be combined to build only certain apps.
  
  Example: ./build.sh --perl            # only perl will be built
           ./build.sh --perl --apache   # only perl and apache will build
           ./build.sh --all             # build all (except wdk)
           ./build.sh --all --with-wdk  # build all including wdk 

  Options:

  --all             builds all packages
  --clean           cleans all pre-req folders for a new build
  --help            displays this screen
  --ia64            turns on special flags for building on 64-bit systems


  Packages:         (must be built in the order shown below)

  --utilities       compiles and installs shared utilities
  --perl            compiles and installs perl
  --apache          compiles and installs apache
  --mysql           compiles and installs mysql
  --imagemagick     compiles and installs image magick
  --perlmodules     installs perl modules from cpan
  --awstats         installs awstats
  --wre             installs WebGUI Runtime Environment scripts and API
                               
_WREHELP

}

#Evaluate options passed by command line
for opt in "$@"
do

  #get any argument passed with this option
  arg=`expr "x$opt" : 'x[^=]*=\(.*\)'`

  case "$opt" in
 
    --ia64)
      export WRE_IA64=1
    ;;

    --clean)
      export WRE_CLEAN=1
    ;;

    --all)
        export WRE_BUILD_UTILS=1
        export WRE_BUILD_PERL=1
        export WRE_BUILD_APACHE=1
        export WRE_BUILD_MYSQL=1
        export WRE_BUILD_IMAGEMAGICK=1
        export WRE_BUILD_AWSTATS=1
        export WRE_BUILD_WRE=1
        export WRE_BUILD_PM=1
    ;;
 
    --utils | --utilities)
        export WRE_BUILD_UTILS=1
    ;;
    
    --perl)
        export WRE_BUILD_PERL=1
    ;;
    
    --apache)
        export WRE_BUILD_APACHE=1
    ;;

# If we wanted to use argument passing on build flags this is how we'd do it
#    --apache=*)
#      echo $arg
#      #Use $arg as parameter to function call, could be used
#      #to pass compile flags for performance, etc.
#    ;;
    
    --mysql)
        export WRE_BUILD_MYSQL=1
    ;;
    
    --imageMagick | --imagemagick)
        export WRE_BUILD_IMAGEMAGICK=1
    ;;
    
    --awstats)
        export WRE_BUILD_AWSTATS=1
    ;;
    
    --wre)
        export WRE_BUILD_WRE=1
    ;;
    
    --perlModules | --perlmodules | --pm)
        export WRE_BUILD_PM=1
    ;;
    
    --help | -help | -h | -? | ?)
      wrehelp
      exit 0
    ;;
    
    -*)
        echo "Error: I don't know this option: $opt"
        echo
        wrehelp
        exit 1
    ;;

  esac
done

#No arguments passed, display help
if [ $# -eq 0 ]; then
    wrehelp
    exit 0
fi

if [ -d /data ]; then

    # configure environment
    . wre/sbin/setenvironment.sh
    export WRE_BUILDDIR=`pwd`
    export WRE_ROOT=/data/wre
    export PREFIX="$WRE_ROOT/prereqs"
    export CC="gcc"
    export CXX="g++"
    export LD="ld"
    export CPPFLAGS="-I$PREFIX/include" 
    export CFLAGS="$CFLAGS -O3 -I$PREFIX/include"
    export CXXFLAGS="$CPPFLAGS -O3 -I$PREFIX/include"
    export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
    export LIBS="-L$PREFIX/lib"
    export LD_LIBRARY_PATH="$PREFIX/include"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export PERLCFGOPTS="-Aldflags=\"-L$PREFIX/lib\""

    # --cache-file speeds up configure a lot
    rm /tmp/Configure.cache
    export CFG_CACHE=""  #"--cache-file=/tmp/Configure.cache"
    if [ "$WRE_IA64" == 1 ]; then
        export CFLAGS="$CFLAGS -fPIC"
        export CXXFLAGS="$CXXFLAGS -fPIC"
        export PERLCFGOPTS="-Accflags=\"-fPIC\" $PERLCFGOPTS"
    fi

    # deal with operating system inconsistencies
    export WRE_OSNAME=`uname -s`
    case $WRE_OSNAME in
        FreeBSD | OpenBSD)
            export WRE_MAKE=gmake
        ;;
        Linux)
            export WRE_MAKE=make
            if [ -f /etc/redhat-release ]; then
                export WRE_OSTYPE="RedHat"
            fi
            if [ -f /etc/fedora-release ]; then
                export WRE_OSTYPE="Fedora"
            fi
            if [ -f /etc/slackware-release ] || [ -f /etc/slackware-version ]; then
                export WRE_OSTYPE="Slackware"
            fi
            if [ -f /etc/debian_release ] || [ -f /etc/debian_version ]; then
                export WRE_OSTYPE="Debian"
            fi
            if [ -f /etc/mandrake-release ]; then
                export WRE_OSTYPE="Mandrake"
            fi
            if [ -f /etc/yellowdog-release ]; then
                export WRE_OSTYPE="YellowDog"
            fi
            if [ -f /etc/gentoo-release ]; then
                export WRE_OSTYPE="Gentoo"
            fi
            if [ -f /etc/lsb-release ]; then
                export WRE_OSTYPE="Ubuntu"
            fi
        ;;
        Darwin)
            export WRE_MAKE=make
            VERSION=`uname -r | cut -d. -f1` 
            if [ $VERSION == "10" ]; then
                export WRE_OSTYPE="Snow Leopard"
                export MACOSX_DEPLOYMENT_TARGET=10.6
                export CFLAGS="-m32 -arch i386 -g -Os -pipe -no-cpp-precomp $CFLAGS"
                export CCFLAGS="-m32 -arch i386 -g -Os -pipe -no-cpp-precomp $CCFLAGS"
                export CXXFLAGS="-m32 -arch i386 -g -Os -pipe $CXXFLAGS"
                export LDFLAGS="-m32 -arch i386 -bind_at_load $LDFLAGS"
                export CFG_LIBGCRYPT="--disable-asm"
                export PERLCFGOPTS="-Ald=\"-m32\" -Accflags=\"-m32\" -Aldflags=\"-m32\" -Acppflags=\"-m32\""
            fi
            if [ $VERSION == "9" ]; then
                export WRE_OSTYPE="Leopard"
            fi 
            if [ $VERSION == "8" ]; then
                export WRE_OSTYPE="Tiger"
            fi 
        ;;
    esac

    ### Program-specific options
    # Perl ./Config options
    export PERLCFGOPTS="$PERLCFGOPTS -Dprefix=$PREFIX -des"

    # Mysql Configure vars
    export MYSQL_CFLAGS="$CFLAGS -fno-omit-frame-pointer"
    export MYSQL_CXXFLAGS="$CXXFLAGS -fno-omit-frame-pointer -felide-constructors \
        -fno-exceptions -fno-rtti" 

    # ImageMagick options
    case "$WRE_OSNAME" in
        FreeBSD | OpenBSD)
            export IM_OPTION="--without-threads"
        ;;
    esac

    # made folders than don't exist
    mkdir -p $PREFIX/man/man1
    mkdir -p $PREFIX/conf
    mkdir -p $PREFIX/lib
    mkdir -p $PREFIX/libexec
    mkdir -p $PREFIX/include
    mkdir -p $PREFIX/var
    mkdir -p $PREFIX/bin

else
    echo "You must create a writable /data folder to begin."
    exit 0
fi


# error
checkError(){
    if [ $1 -ne 0 ];
    then
        echo "WRE ERROR: "$2" did not complete successfully."
        exit
    fi
}

printHeader(){
    echo "### ----------------------------------- ###"
    echo "#### Building $1       "
}

# most programs build the same
# param 1: folder name
# param 2: configure params
# param 3: make install params
# param 4: compiler flags

buildProgram() {
    cd $1
    printHeader $1
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    echo "Configuring $1 with GNUMAKE=$WRE_MAKE $4 ./configure --prefix=$PREFIX $2"
    $4 ./configure --prefix=$PREFIX $2; checkError $? "$1 configure"
    $WRE_MAKE; checkError $? "$1 make"
    $WRE_MAKE install $3; checkError $? "$1 make install"
    cd ..
}

# utilities
buildUtils(){
    printHeader "Utilities"
    cd source

    # libtool
    buildProgram "libtool-2.4.2"

    # ncurses
    buildProgram "ncurses-5.9" "$CFG_CACHE --with-shared "

    # zlib
    buildProgram "zlib-1.2.6" "--shared"

    # openssl
    cd openssl-1.0.1b
    printHeader "openssl"
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    ./config --prefix=$PREFIX shared ; checkError $? "openssl configure"
    $WRE_MAKE; checkError $? "openssl make"
    $WRE_MAKE install; checkError $? "openssl make install"
    cd ..

    # libiconv
    if [ "$WRE_OSNAME" != "Darwin" ] && [ "$WRE_OSTYPE" != "Leopard" ]; then
        buildProgram "libiconv-1.14" "$CFG_CACHE"
    fi

    ## rsync
    #buildProgram "rsync-3.0.6" "$CFG_CACHE"

    ## libgpg-error
    buildProgram "libgpg-error-1.7" "$CFG_CACHE"

    # libgmp
    buildProgram "gmp-5.0.5" "$CFG_CACHE ABI=32"

    # libnettle
    buildProgram "nettle-2.4" "$CFG_CACHE"

    # p11-kit
    buildProgram "p11-kit-0.12" "$CFG_CACHE"

    # gnutls
    buildProgram "gnutls-2.12.19" "$CFG_CACHE"

    # expat
    buildProgram "expat-2.1.0" "$CFG_CACHE"

    # lib xml
    buildProgram "libxml2-2.7.8" "$CFG_CACHE"

    # readline
    buildProgram "readline-6.2" "$CFG_CACHE"

    # pcre
    buildProgram "pcre-8.30" "$CFG_CACHE"

    # curl
    buildProgram "curl-7.25.0" "$CFG_CACHE --with-ssl=$PREFIX --with-zlib=$PREFIX --with-gnutls=$PREFIX"

    # lftp
    SAVED_CFLAGS=$CFLAGS
    CFLAGS="$CFLAGS -liconv"
    buildProgram "lftp-4.3.6" "--with-libiconv-prefix=$PREFIX --with-openssl=$PREFIX"
    CFLAGS=$SAVED_CFLAGS
    
    # catdoc
    cd catdoc-0.94.2
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    CATDOCARGS="--disable-wordview --without-wish --with-input=utf-8 \
        --with-output=utf-8 --disable-charset-check --disable-langinfo"
    ./configure $CFG_CACHE --prefix=$PREFIX $CATDOCARGS; checkError $? "catdoc Configure"
    $WRE_MAKE; checkError $? "catdoc make"
    cd src
    $WRE_MAKE install; checkError $? "catdoc make install src"
    cd ../docs
    $WRE_MAKE install; checkError $? "catdoc make install docs"
    cd ../charsets
    $WRE_MAKE install; checkError $? "catdoc make install charsets"
    cd ../..

    # xpdf
    buildProgram "xpdf-3.03" "$CFG_CACHE --without-x"

    cd $WRE_BUILDDIR
}

# perl
buildPerl(){
    printHeader "Perl"
    cd source/perl-5.14.2
    if [ "$WRE_CLEAN" == 1 ]; then
            $WRE_MAKE distclean
            $WRE_MAKE clean
    fi
    ./Configure $PERLCFGOPTS; checkError $? "Perl Configure" 
    $WRE_MAKE; checkError $? "Perl make"
    $WRE_MAKE install; checkError $? "Perl make install"
    cd $WRE_BUILDDIR
}


# apache
buildApache(){
    printHeader "Apache"
    cd source

    # apache
    cd httpd-2.2.22
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
        #rm -Rf server/exports.c 
        #rm -Rf server/export_files
    fi
    SAVED_CPPFLAGS=$CPPFLAGS
    CPPFLAGS=""
    SAVED_CFLAGS=$CFLAGS
    CFLAGS=""
    SAVED_LIBS=$LIBS
    LIBS=""
    SAVED_LDFLAGS=$LDFLAGS
    LDFLAGS=""
    ./configure $CFG_CACHE --prefix=$PREFIX --with-included-apr --with-z=$PREFIX \
        --sysconfdir=$WRE_ROOT/etc --localstatedir=$WRE_ROOT/var \
        --enable-rewrite=shared --enable-deflate=shared --enable-ssl \
        --with-ssl=$PREFIX --enable-proxy=shared --with-mpm=prefork \
        --enable-headers --disable-userdir --disable-imap --disable-negotiation \
        --disable-actions --enable-expires=shared; 
    checkError $? "Apache Configure"
    if [ "$WRE_OSNAME" == "Darwin" ] && [ "$WRE_OSTYPE" == "Leopard" ]; then
        $PREFIX/bin/perl -i -p -e's[#define APR_HAS_SENDFILE          1][#define APR_HAS_SENDFILE          0]g' srclib/apr/include/apr.h
    fi
    $WRE_MAKE; checkError $? "Apache make"
    $WRE_MAKE install; checkError $? "Apache make install"
    rm -f $WRE_ROOT/etc/highperformance-std.conf
    rm -f $WRE_ROOT/etc/highperformance.conf
    rm -f $WRE_ROOT/etc/httpd-std.conf 
    rm -f $WRE_ROOT/etc/httpd.conf 
    rm -f $WRE_ROOT/etc/ssl-std.conf
    rm -f $WRE_ROOT/etc/ssl.conf
    CFLAGS=$SAVED_CFLAGS
    CPPFLAGS=$SAVED_CPPFLAGS
    LDFLAGS=$SAVED_LDFLAGS
    LIBS=$SAVED_LIBS

    # modperl
    cd ../mod_perl-2.0.7
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    perl Makefile.PL MP_APR_CONFIG="$PREFIX/bin/apr-1-config" MP_APU_CONFIG="$PREFIX/bin/apu-1-config" MP_APXS="$PREFIX/bin/apxs"; checkError $? "mod_perl Configure"
    $WRE_MAKE; checkError $? "mod_perl make"
    $WRE_MAKE install; checkError $? "mod_perl make install"
    cd ..

    cd $WRE_BUILDDIR
}


# mysql
buildMysql(){
    printHeader "MySQL"
    cd source/mysql-5.1.62
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
    fi
    SAVED_CFLAGS="$CFLAGS"
    SAVED_CXXFLAGS="$CXXFLAGS"
    CFLAGS="$MYSQL_CFLAGS"
    CXXFLAGS="$MYSQL_CXXFLAGS"
    # Can't use $CFG_CACHE because CFLAGS changed
    ./configure --prefix=$PREFIX --sysconfdir=$WRE_ROOT/etc --localstatedir=$WRE_ROOT/var/mysqldata --with-extra-charsets=all --enable-thread-safe-client --enable-local-infile --disable-shared --enable-assembler --with-readline --without-debug --enable-largefile=yes --with-ssl --with-mysqld-user=webgui --with-unix-socket-path=$WRE_ROOT/var/mysqldata/mysql.sock --without-docs --without-man; checkError $? "MySQL Configure"
    $WRE_MAKE; checkError $? "MySQL make"
    $WRE_MAKE install; checkError $? "MySQL make install"
    cd $WRE_BUILDDIR
    CFLAGS="$SAVED_CFLAGS"
    CXXFLAGS="$SAVED_CXXFLAGS"
}


# Image Magick
buildImageMagick(){

    printHeader "Image Magick"
    cd source

    # lib jpeg
    cd libjpeg-8
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    ./configure $CFG_CACHE --prefix=$PREFIX; checkError $? "libjpeg Configure"
    #$PREFIX/bin/perl -i -p -e's[./libtool][libtool]g' Makefile
    $WRE_MAKE; checkError $? "libjpeg make"
    $WRE_MAKE install; checkError $? "libjpeg make install"
    cd ..

    # freetype
    buildProgram "freetype-2.4.9" "$CFG_CACHE"

    # lib ungif
    buildProgram "giflib-4.1.6" "$CFG_CACHE"

    # tiff 
    buildProgram "tiff-3.9.6" "$CFG_CACHE"

    # lib png
    buildProgram "libpng-1.5.10" "$CFG_CACHE"

    # lcms 
    buildProgram "lcms2-2.3" "$CFG_CACHE"

    # graphviz
    buildProgram "graphviz-2.24.0" "$CFG_CACHE --enable-static --with-libgd=no --with-mylibgd=no --disable-java --disable-swig --disable-perl --disable-python --disable-php --disable-ruby --disable-sharp --disable-python23 --disable-python24 --disable-python25 --disable-r --disable-tcl --disable-guile --disable-io --disable-lua --disable-ocaml"
    ln -s $PREFIX/bin/dot_static $PREFIX/bin/dot 


    # image magick
    cd ImageMagick-* # when you update this version number, update the one below as well
    printHeader "Image Magick"
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    if [ "$WRE_IA64" == 1 ]; then
        SAVED_LDFLAGS="$LDFLAGS"
        LDFLAGS="$LDFLAGS -L$PREFIX/lib -L$PREFIX/lib/perl5/lib -L$PREFIX/lib/perl5/5.10.1/x86_64-linux/CORE"
    fi
    # For some reason the CFG_CACHE causes compile to fail
    ./configure --prefix=$PREFIX --with-zlib=$PREFIX --enable-delegate-build --enable-shared --with-gvc --with-jp2 --with-jpeg --with-png --with-perl --with-lcms --with-tiff --without-x GVC_CFLAGS=-I$PREFIX/include/graphviz GVC_LIBS="-L$PREFIX/lib -lgvc -lgraph -lcdt" $IM_OPTION; checkError $? "Image Magick configure"
    if [ "$WRE_OSNAME" == "Darwin" ]; then # technically this is only for Darwin i386, but i don't know how to detect that
        $PREFIX/bin/perl -i -p -e's[\#if defined\(PNG_USE_PNGGCCRD\) \&\& defined\(PNG_ASSEMBLER_CODE_SUPPORTED\) \\][#if FALSE]g' coders/png.c
    fi
    $WRE_MAKE; checkError $? "Image Magick make"
    $WRE_MAKE install; checkError $? "Image Magick make install"

    cd $WRE_BUILDDIR
    cp source/colors.xml $PREFIX/lib/ImageMagick-6.7.6/config/

    if [ "$WRE_IA64" == 1 ]; then
        LDFLAGS="$SAVED_LDFLAGS"
    fi
}

# most perl modules are installed the same way
# param1: module directory
# param2: parameters to pass to Makefile.PL
installPerlModule() {
    cd $1
    printHeader "PM $1 with $2"
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi
    perl Makefile.PL $2 CCFLAGS="$CFLAGS"; checkError $? "$1 Makefile.PL"
    $WRE_MAKE; checkError $? "$1 make"
    #$WRE_MAKE test; checkError $? "$1 make test"
    $WRE_MAKE install; checkError $? "$1 make install"
    cd ..
}

# some other perl modules are installed the same way
# param1: module directory
# param2: parameters to pass to Makefile.PL
buildPerlModule() {
    cd $1
    printHeader "PM $1"
    if [ "$WRE_CLEAN" == 1 ]; then
        perl Build clean
    fi
    perl Build.PL $2; checkError $? "$1 Build.PL"
    perl Build; checkError $? "$1 Build"
    perl Build install; checkError $? "$1 Build install"
    cd ..
}

installPerlModules () {
    printHeader "Perl Modules"
    cd source/perlmodules
    export PERL_MM_USE_DEFAULT=1 # makes it so perl modules don't ask questions
    if [ "$WRE_OSTYPE" != "Leopard" ] && [ "$WRE_OSTYPE" != "Snow Leopard" ]; then
        installPerlModule "Proc-ProcessTable-0.44"
    fi
    installPerlModule "Test-Tester-0.107"
    installPerlModule "Test-NoWarnings-1.02"
    installPerlModule "Test-Deep-0.103"
    installPerlModule "Test-MockObject-1.20110612"
    buildPerlModule "UNIVERSAL-isa-1.03"
    buildPerlModule "UNIVERSAL-can-1.15"
    installPerlModule "common-sense-3.4"
    installPerlModule "Net-SSLeay-1.36" "$PREFIX"
    installPerlModule "Compress-Raw-Zlib-2.015"
    installPerlModule "IO-Compress-Base-2.015"
    installPerlModule "IO-Compress-Zlib-2.015"
    installPerlModule "Compress-Zlib-2.015"
    installPerlModule "BSD-Resource-1.2902"
    installPerlModule "URI-1.51"
    installPerlModule "IO-Zlib-1.09"
    installPerlModule "HTML-Tagset-3.20"
    installPerlModule "HTML-Parser-3.64"
    installPerlModule "libwww-perl-5.834" "-n"
    installPerlModule "CGI.pm-3.42"
    installPerlModule "Digest-HMAC-1.01"
    installPerlModule "Digest-MD5-2.39"
    installPerlModule "Digest-SHA1-2.12"
    installPerlModule "Module-Build-0.31012"
    installPerlModule "Params-Validate-0.91"
    installPerlModule "List-MoreUtils-0.22"
    installPerlModule "Scalar-List-Utils-1.19"
    buildPerlModule "Devel-StackTrace-1.20"
    installPerlModule "DateTime-Locale-0.42"
    installPerlModule "Class-Singleton-1.4"
    installPerlModule "DateTime-TimeZone-0.84"
    installPerlModule "Time-Local-1.1901"
    installPerlModule "Test-Simple-0.94"
    installPerlModule "Devel-Symdump-2.08"
    installPerlModule "Pod-Escapes-1.04"
    installPerlModule "ExtUtils-CBuilder-0.24"
    installPerlModule "Pod-Coverage-0.19"
    installPerlModule "Pod-Simple-3.10"
    installPerlModule "podlators-2.2.2"
    installPerlModule "DateTime-0.4501"
    installPerlModule "DateTime-Format-Strptime-1.0800"
    installPerlModule "HTML-Template-2.9"
    installPerlModule "Crypt-SSLeay-0.57" "--lib=$PREFIX" # on upgrade mod Makefile.PL to remove network tests
    buildPerlModule "String-Random-0.22"
    installPerlModule "Time-HiRes-1.9719"
    installPerlModule "Text-Balanced-v2.0.0"
    installPerlModule "Tie-IxHash-1.21"
    installPerlModule "Tie-CPHash-1.04"
    installPerlModule "Error-0.17016"
    installPerlModule "HTML-Highlight-0.20"
    installPerlModule "HTML-TagFilter-1.03"
    installPerlModule "IO-String-1.08"
    installPerlModule "Archive-Tar-1.44"
    installPerlModule "Archive-Zip-1.26"
    installPerlModule "XML-NamespaceSupport-1.09"
    installPerlModule "XML-SAX-Base-1.02"
    installPerlModule "XML-Parser-2.36" "EXPATLIBPATH=$PREFIX/lib EXPATINCPATH=$PREFIX/include"
    installPerlModule "XML-SAX-0.96"
    installPerlModule "XML-SAX-Expat-0.40"
    installPerlModule "XML-Simple-2.18"
    installPerlModule "XML-RSSLite-0.11"
    installPerlModule "SOAP-Lite-0.710.08" "--noprompt"
    installPerlModule "DBI-1.615"
    installPerlModule "DBD-mysql-4.018"
    installPerlModule "Convert-ASN1-0.22"
    installPerlModule "HTML-TableExtract-2.10"
    installPerlModule "HTML-Tree-3.23"
    installPerlModule "Finance-Quote-1.17"
    installPerlModule "JSON-XS-2.26"
    installPerlModule "JSON-2.17"
    installPerlModule "version-0.76"
    installPerlModule "Path-Class-0.16"
    installPerlModule "Mouse-0.93"
    installPerlModule "Any-Moose-0.15"
    installPerlModule "Config-JSON-1.5100"
    installPerlModule "IO-Socket-SSL-1.22"
    #installPerlModule "Text-Iconv-1.7" ##Replaced by Encode for XML::SAX::Writer
    installPerlModule "XML-Filter-BufferText-1.01"
    installPerlModule "XML-SAX-Writer-0.53"
    export AUTHEN_SASL_VERSION="Authen-SASL-2.12"
    $PREFIX/bin/perl -ni -e 'print unless /GSSAPI mechanism/ .. /\],/' $AUTHEN_SASL_VERSION/Makefile.PL
    installPerlModule $AUTHEN_SASL_VERSION
    export LDAP_VERSION="perl-ldap-0.39"
    $PREFIX/bin/perl -i -p -e"s[check_module\('Authen::SASL', 2.00\) or print <<\"EDQ\",\"\\\n\";][print <<\"EDQ\",\"\\\n\";]g" $LDAP_VERSION/Makefile.PL
    $PREFIX/bin/perl -i -nl -e"print unless /'SASL authentication' => \[/../\],/" $LDAP_VERSION/Makefile.PL
    installPerlModule $LDAP_VERSION
    installPerlModule "Log-Log4perl-1.20"
    installPerlModule "POE-1.283" "--default"
    installPerlModule "POE-Component-IKC-0.2002"
    installPerlModule "String-CRC32-1.4"
    installPerlModule "ExtUtils-XSBuilder-0.28"
    installPerlModule "ExtUtils-MakeMaker-6.48"
    installPerlModule "trace-0.551" # TODO: replace by Devel::XRay
    installPerlModule "Clone-0.31"
    installPerlModule "Test-Pod-1.26"
    installPerlModule "Data-Structure-Util-0.15"
    installPerlModule "Parse-RecDescent-1.96.0"
    printHeader "libaqpreq2"
    cd libapreq2-2.08
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi  
    ./configure $CFG_CACHE --with-apache2-apxs=$PREFIX/bin/apxs --enable-perl-glue; checkError $? "libapreq2 configure"
    $WRE_MAKE; checkError $? "libapreq2 make"
    $WRE_MAKE install; checkError $? "libapreq2 make install"
    cd ..
    installPerlModule "Net-CIDR-Lite-0.20"
    installPerlModule "MailTools-2.04"
    installPerlModule "IO-stringy-2.110"
    installPerlModule "MIME-tools-5.427"
    installPerlModule "HTML-Template-Expr-0.07"
    installPerlModule "Template-Toolkit-2.22" "TT_ACCEPT=y TT_DOCS=n TT_SPLASH=n TT_THEME=n TT_EAMPLES=n TT_EXTRAS=n TT_XS_STASH=y TT_XS_DEFAULT=n TT_DBI=n TT_LATEX=n"
    installPerlModule "Scalar-List-Utils-1.19"
    installPerlModule "Graphics-ColorNames-2.11"
    installPerlModule "Module-Load-0.16"
    installPerlModule "Color-Calc-1.05"
    installPerlModule "DateTime-Format-Mail-0.3001"
    installPerlModule "Digest-BubbleBabble-0.01"
    installPerlModule "Net-IP-1.25"
    installPerlModule "Net-DNS-0.65" "--noonline-tests"
    installPerlModule "POE-Component-Client-DNS-1.051"
    installPerlModule "POE-Component-Client-Keepalive-0.262"
    installPerlModule "POE-Component-Client-HTTP-0.893"
    installPerlModule "Class-MakeMethods-1.01"
    installPerlModule "Locale-US-1.2"
    installPerlModule "Time-Format-1.09"
    installPerlModule "Weather-Com-0.5.3"
    installPerlModule "File-Slurp-9999.13"
    installPerlModule "Text-CSV_XS-0.69"
    installPerlModule "File-Temp-0.21"
    installPerlModule "File-Path-2.07"
    installPerlModule "File-Which-0.05"
    installPerlModule "Class-InsideOut-1.09"
    installPerlModule "HTML-TagCloud-0.34"
    installPerlModule "Set-Infinite-0.63"
    installPerlModule "DateTime-Set-0.26"
    installPerlModule "DateTime-Event-Recurrence-0.16"
    installPerlModule "DateTime-Event-ICal-0.09"
    installPerlModule "MIME-Types-1.27"
    installPerlModule "File-MMagic-1.27"
    buildPerlModule "PathTools-3.29"
    installPerlModule "Module-Find-0.06"
    buildPerlModule "Archive-Any-0.0932"
    installPerlModule "Image-ExifTool-8.00"
    # aspell
    cd ..
    buildProgram "aspell-0.60.6" "" "exec_prefix=$PREFIX"
    cd aspell6-en-6.0-0
    if [ "$WRE_CLEAN" == 1 ]; then
        $WRE_MAKE distclean
        $WRE_MAKE clean
    fi  
    ./configure --vars ASPELL=$PREFIX/bin/aspell WORD_LIST_COMPRESS=$PREFIX/bin/word-list-compress; checkError $? "aspell-en configure"
    $WRE_MAKE; checkError $? "aspell-en make"
    $WRE_MAKE install ; checkError $? "aspell-en make install"
    cd ../perlmodules
    installPerlModule "Text-Aspell-0.09" "LIBS='-laspell'"
    # back to perl modules
    cd MySQL-Diff-0.33
    perl Makefile.PL; checkError $? "MySQL::Diff Makefile.PL"
    $WRE_MAKE; checkError $? "MySQL::Diff make"
    $WRE_MAKE install; checkError $? "MySQL::Diff make install"
    cp -f mysqldiff $WRE_ROOT/sbin/
    perl -i -p -e's[/usr/bin/perl][$WRE_ROOT/prereqs/bin/perl]g' $WRE_ROOT/sbin/mysqldiff
    cd ..
    installPerlModule "Class-Data-Inheritable-0.08"
    installPerlModule "Exception-Class-1.26"
    installPerlModule "Algorithm-C3-0.07"
    installPerlModule "Class-C3-XS-0.11"
    installPerlModule "Class-C3-0.21"
    installPerlModule "XML-TreePP-0.38"
    installPerlModule "XML-FeedPP-0.40"
    installPerlModule "Sub-Uplevel-0.2002"
    installPerlModule "Readonly-1.03"
    installPerlModule "Carp-Assert-0.20"
    installPerlModule "Test-Exception-0.27"
    installPerlModule "Carp-Assert-More-1.12"
    installPerlModule "HTTP-Server-Simple-0.44"
    installPerlModule "Test-LongString-0.15"
    installPerlModule "HTTP-Response-Encoding-0.05"
    installPerlModule "Array-Compare-2.01"
    installPerlModule "Tree-DAG_Node-1.06"
    installPerlModule "Test-Warn-0.11"
    installPerlModule "Devel-Cycle-1.10"
    installPerlModule "PadWalker-1.7"
    installPerlModule "Test-Memory-Cycle-1.04"
    installPerlModule "Test-Taint-1.04"
    installPerlModule "WWW-Mechanize-1.54"
    installPerlModule "Test-WWW-Mechanize-1.24"
    installPerlModule "Test-JSON-0.06"
    installPerlModule "IPC-Run-0.82"
    installPerlModule "GraphViz-2.04"
    installPerlModule "Class-Member-1.6"
    # detecting shared memory properly on 2.6 kernels
    if [ "$WRE_OSNAME" == "Linux" ]; then
        installPerlModule "Linux-Smaps-0.09" 
    fi
    # 7.7.5
    installPerlModule "Regexp-RegGrp-1.002"
    installPerlModule "HTML-Packer-1.002001"
    installPerlModule "JavaScript-Packer-1.004"
    installPerlModule "CSS-Packer-1.002"
    # 7.7.6
    installPerlModule "Business-Tax-VAT-Validation-0.20"
    installPerlModule "Scope-Guard-0.03"
    # 7.7.7
    installPerlModule "Digest-SHA-5.47"
    installPerlModule "JavaScript-Minifier-XS-0.05"
    installPerlModule "CSS-Minifier-XS-0.03" 
    installPerlModule "Test-Class-0.31"
    # payment modules
SAVED_IFS=$IFS
IFS=";"
    installPerlModule "Crypt-OpenSSL-Random-0.04"
    installPerlModule "Crypt-OpenSSL-RSA-0.26"
IFS=$SAVED_IFS
    installPerlModule "Crypt-CBC-2.30"
    installPerlModule "YAML-0.68"
    installPerlModule "Math-BigInt-FastCalc-0.19"
    installPerlModule "Crypt-DH-0.06"
    installPerlModule "LWPx-ParanoidAgent-1.04"
    installPerlModule "Net-OpenID-Consumer-1.03"
    installPerlModule "Crypt-RC4-2.02"
    installPerlModule "Text-PDF-0.29"
    installPerlModule "CAM-PDF-1.52"
    installPerlModule "Text-Diff-HTML-0.06"
    installPerlModule "Locales-0.19"
    installPerlModule "Test-Harness-3.17"
    # App-Nopaste
    installPerlModule "Params-Util-1.00"
    installPerlModule "Sub-Install-0.925"
    installPerlModule "Data-OptList-0.104"
    installPerlModule "Sub-Exporter-0.982"
    installPerlModule "Devel-GlobalDestruction-0.02"
    installPerlModule "MRO-Compat-0.11"
    installPerlModule "Sub-Name-0.04"
    installPerlModule "Task-Weaken-1.03"
    installPerlModule "Try-Tiny-0.02"
SAVED_CFLAGS=$CFLAGS
CFLAGS="$CFLAGS -I."
    installPerlModule "Class-MOP-0.97"
CFLAGS=$SAVED_CFLAGS
    installPerlModule "Moose-0.93"
    installPerlModule "Getopt-Long-Descriptive-0.081"
    installPerlModule "MooseX-Getopt-0.25"
    installPerlModule "WWW-Pastebin-PastebinCom-Create-0.003"
    installPerlModule "Class-Data-Accessor-0.04004"
    installPerlModule "WWW-Pastebin-RafbNet-Create-0.001"
    installPerlModule "Spiffy-0.30"
    installPerlModule "Clipboard-0.09"
    installPerlModule "Mixin-Linewise-0.002"
    installPerlModule "Config-INI-0.014"
    installPerlModule "App-Nopaste-0.17"
    installPerlModule "Business-PayPal-API-rel-0.69"

    cd $WRE_BUILDDIR
}


#awstats
installAwStats(){
    printHeader "AWStats"
    cp -RL source/awstats-7.0/* $PREFIX
}

#wre utils
installWreUtils(){
    printHeader "WebGUI Runtime Environment Core and Utilities"
    cp -Rf wre /data/
    if [ ! -d "$WRE_ROOT/etc" ]; then
            mkdir $WRE_ROOT/etc
    fi
}

# make the WRE distro smaller by getting rid of non-essential stuff
makeItSmall(){
    printHeader "Making WRE smaller"
    rm -Rf $PREFIX/man
    rm -Rf $PREFIX/manual
    rm -Rf $PREFIX/sql-bench
    rm -Rf $PREFIX/mysql-test
    rm -Rf $PREFIX/README.TXT
    rm -Rf $PREFIX/docs
    rm -Rf $PREFIX/share/doc
    rm -Rf $PREFIX/share/gtk-doc
    rm -Rf $PREFIX/share/man
    rm -Rf $PREFIX/share/ImageMagick*
    rm -Rf $WRE_ROOT/etc/original
    rm -Rf $WRE_ROOT/etc/extra
}

# build stuff
if [ "$WRE_BUILD_UTILS" == 1 ]; then
    buildUtils
fi
if [ "$WRE_BUILD_PERL" == 1 ]; then
    buildPerl
fi
if [ "$WRE_BUILD_APACHE" == 1 ]; then
    buildApache
fi
if [ "$WRE_BUILD_MYSQL" == 1 ]; then
    buildMysql
fi
if [ "$WRE_BUILD_IMAGEMAGICK" == 1 ]; then
    buildImageMagick
fi
if [ "$WRE_BUILD_PM" == 1 ]; then
    #installPerlModules
    echo "no perl modules"
fi
if [ "$WRE_BUILD_AWSTATS" == 1 ]; then
    installAwStats
fi
if [ "$WRE_BUILD_WRE" == 1 ]; then
    installWreUtils
fi
makeItSmall
printHeader "Complete And Successful"



