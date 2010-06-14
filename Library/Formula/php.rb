require 'formula'

def mysql_installed?
    `which mysql_config`.length > 0
end

class Php <Formula
  url 'http://www.php.net/get/php-5.3.2.tar.gz/from/this/mirror'
  homepage 'http://php.net/'
  md5 '4480d7c6d6b4a86de7b8ec8f0c2d1871'
  version '5.3.2'

  # So PHP extensions don't report missing symbols
  def skip_clean? path
    true
  end

  depends_on 'pcre'
  depends_on 'jpeg'
#  depends_on 'mcrypt'
#  depends_on 'gettext'
  if ARGV.include? '--with-mysql'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
#  if ARGV.include? '--with-intl'
#    depends_on 'icu4c'
#  end

  def options
   [
     ['--with-mysql', 'Build with MySQL support.'],
     ['--with-freetype', 'Build with Freetype support.'],
     ['--with-intl', 'Build with internationalization support.']
   ]
  end

  def patches
   DATA
  end
  
  def configure_args
    args = [
      "--prefix=#{prefix}",
      "--mandir=#{man}",
      "--infodir=#{info}",
      "--disable-dependency-tracking",
      "--sysconfdir=/private/etc",
      "--with-apxs2=/usr/sbin/apxs",
      "--enable-cli",
      "--with-config-file-path=/etc",
      "--with-libxml-dir=/usr",
      "--with-openssl=/usr",
      "--with-kerberos=/usr",
      "--with-zlib=/usr",
      "--enable-bcmath",
      "--with-bz2=/usr",
      "--enable-calendar",
      "--with-curl=/usr",
      "--enable-exif",
      "--enable-ftp",
      "--with-gd",
      "--with-png-dir=/usr/X11R6",
      "--enable-gd-native-ttf",
      "--with-ldap=/usr",
      "--with-ldap-sasl=/usr",
      "--enable-mbstring",
      "--enable-mbregex",
      "--with-iodbc=/usr",
      "--enable-shmop",
      "--with-snmp=/usr",
      "--enable-soap",
      "--enable-sockets",
      "--enable-sysvmsg",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--with-xmlrpc",
      "--with-xsl=/usr",
      "--enable-zend-multibyte",
      "--enable-zip",
      "--with-pcre-regex=/usr",
      "--with-pear",
##       "--disable-debug",
      "--with-iconv-dir=/usr",
##       "--enable-sqlite-utf8",
##       "--enable-wddx",
##       "--enable-pcntl",
##       "--enable-memory-limit",
##       "--enable-memcache",
##       "--with-mcrypt=#{Formula.factory('mcrypt').prefix}",
      "--with-jpeg-dir=#{Formula.factory('jpeg').prefix}",
##       "--with-gettext=#{Formula.factory('gettext').prefix}",
       "--with-tidy",
    ]
    
    if ARGV.include? '--with-freetype'
      args.push "--with-freetype-dir=/usr/X11R6"
    end
    
    if ARGV.include? '--with-intl'
      args.push "--enable-intl"
#      args.push "--with-icu-dir=#{Formula.factory('icu4c').prefix}"
    end

    if ARGV.include? '--with-mysql'
      if mysql_installed?
        args.push "--with-mysql-sock=/tmp/mysql.sock"
        args.push "--with-mysqli=mysqlnd"
        args.push "--with-mysql=mysqlnd"
        args.push "--with-pdo-mysql=mysqlnd"
      else
        args.push "--with-mysqli=#{Formula.factory('mysql').bin}/mysql_config}"
        args.push "--with-mysql=#{Formula.factory('mysql').prefix}"
        args.push "--with-pdo-mysql=#{Formula.factory('mysql').prefix}"
      end
    end
    return args
  end
  
  def install
#    ENV.O3 # Speed things up
    system "./configure", *configure_args

    # Use Homebrew prefix for the Apache libexec folder and prevent apxs from automatically adding a line to the config file.
    inreplace "Makefile",
      "INSTALL_IT = $(mkinstalldirs) '$(INSTALL_ROOT)/usr/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='$(INSTALL_ROOT)/usr/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so",
      "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -n php5 libs/libphp5.so"
    
    if ARGV.include? '--with-intl'
      inreplace "Makefile" do |contents|
        contents.change_make_var! "EXTRA_LIBS", "\\1 -lstdc++"
      end
    end
    
    system "make"
    system "make install"

    # Only copy the php.ini file if they don't have one...
    system "[ -f \"#{prefix}/lib/php.ini\" ] || cp ./php.ini-production #{prefix}/lib/php.ini"
  end

 def caveats; <<-EOS
   For 10.5 and Apache:
    Apache needs to run in 32-bit mode. You can either force Apache to start 
    in 32-bit mode or you can thin the Apache executable. The following page 
    has instructions for both methods:
    http://code.google.com/p/modwsgi/wiki/InstallationOnMacOSX
   
   To enable PHP in Apache add the following to httpd.conf and restart Apache:
    LoadModule php5_module    #{prefix}/libexec/apache2/libphp5.so

    httpd.conf can usually be found in:
    /etc/apache2/httpd.conf

   Edits you will most likely want to make to php.ini
    Date:
      You will want to set date.timezone setting to your timezone.
      http://www.php.net/manual/en/timezones.php

    MySQL:
      pdo_mysql.default_socket = /tmp/mysql.sock
      mysql.default_port = 3306
      mysql.default_socket = /tmp/mysql.sock
      mysqli.default_socket = /tmp/mysql.sock

    You might want to add the following to your php.ini include_path:
    #{prefix}/lib/php
      
    The php.ini file can be found in: 
    #{prefix}/lib/php.ini

   EOS
 end
end

__END__
diff -Naur php-5.3.0/ext/iconv/iconv.c php/ext/iconv/iconv.c
--- php-5.3.0/ext/iconv/iconv.c	2009-03-16 22:31:04.000000000 -0700
+++ php/ext/iconv/iconv.c	2009-07-15 14:40:09.000000000 -0700
@@ -51,9 +51,6 @@
 #include <gnu/libc-version.h>
 #endif
 
-#ifdef HAVE_LIBICONV
-#undef iconv
-#endif
 
 #include "ext/standard/php_smart_str.h"
 #include "ext/standard/base64.h"
@@ -182,9 +179,6 @@
 }
 /* }}} */
 
-#ifdef HAVE_LIBICONV
-#define iconv libiconv
-#endif
 
 /* {{{ typedef enum php_iconv_enc_scheme_t */
 typedef enum _php_iconv_enc_scheme_t {
diff -Naur php-5.3.2/ext/tidy/tidy.c php/ext/tidy/tidy.c 
--- php-5.3.2/ext/tidy/tidy.c	2010-02-12 04:36:40.000000000 +1100
+++ php/ext/tidy/tidy.c	2010-05-23 19:49:47.000000000 +1000
@@ -22,6 +22,8 @@
 #include "config.h"
 #endif
 
+#include "tidy.h"
+
 #include "php.h"
 #include "php_tidy.h"
 
@@ -31,7 +33,6 @@
 #include "ext/standard/info.h"
 #include "safe_mode.h"
 
-#include "tidy.h"
 #include "buffio.h"
 
 /* compatibility with older versions of libtidy */
