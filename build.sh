#!/bin/sh
set -eu

selection=${1:-all}
mkdir -p /opt/perls /tmp/all-perl-build

while read -r version url <&3; do
    case "$version" in ''|'#'*) continue ;; esac
    if [ "$selection" != all ]; then
        case " $selection " in *" $version "*) ;; *) continue ;; esac
    fi
    echo "Building Perl $version"

    archive=/tmp/all-perl-build/source.tar.gz
    source=/tmp/all-perl-build/source
    rm -rf "$source"
    mkdir -p "$source"
    # shortcut: source archives rely on versioned HTTPS URLs; pin digests before publishing images.
    curl --fail --location --retry 3 --silent --show-error "$url" -o "$archive"
    tar -xzf "$archive" -C "$source" --strip-components=1
    cd "$source"
    [ "$version" != 4.036 ] || cd src

    case "$version" in
        1.*) patch -p1 < /all-perl/patches/perl1-glibc.patch ;;
        2.*|3.*|4.*|5.004_05)
            # shortcut: these Configures reject redirected stdin, remove the obsolete terminal check in a noninteractive build.
            sed -i '/if test ! -t 0; then/,/^fi$/d' Configure
            ;;
        5.004_05)
            libc_path=$(cc -print-file-name=libc.a)
            sed -i "s|^libc=''$|libc='$libc_path'|" Configure
            sed -i "s|^usemymalloc=''$|usemymalloc='n'|" Configure
            ;;
        5.005_04) sed -i '/#ifdef __linux__/,/^#endif/d' ext/IPC/SysV/SysV.xs ;;
        *) patchperl ;;
    esac

    case "$version" in
        2.*)
            patch -p1 < /all-perl/patches/perl2-glibc.patch
            sed -i '/^%type <stabval>$/d' perl.y
            sed -i "s|^usemymalloc=''$|usemymalloc='n'|" Configure
            sed -i '/#include "config.h"/a #include <errno.h>' perl.h
            sed -i 's/errno < 0 || errno > sys_nerr ? "(unknown)" : sys_errlist\[errno\]/strerror(errno)/' stab.c
            sed -i '/^[[:space:]]*extern int errno;$/d' ./*.c
            ;;
        3.*)
            sed -i "s|^mansrc=''$|mansrc='/usr/share/man/man1'|" Configure
            sed -i '/: determine which malloc to compile in/a usemymalloc=n' Configure
            sed -i '/^%type <stabval>$/d' perl.y
            sed -i 's/str_set(str, pwent->pw_comment);/str_set(str, "");/' doio.c
            sed -i '/#include "config.h"/a #include <errno.h>' perl.h
            sed -i 's/sys_errlist\[errno\]/strerror(errno)/g' perly.c stab.c
            sed -i 's/errno < 0 || errno > sys_nerr ? "(unknown)" : strerror(errno)/strerror(errno)/' stab.c
            sed -i '/^[[:space:]]*extern int errno;$/d' ./*.c
            ;;
        4.*)
            patch -p1 < /all-perl/patches/perl4-debug.patch
            sed -i '/: determine which malloc to compile in/a usemymalloc=n' Configure
            ;;
    esac

    prefix=/opt/perls/$version
    sh ./Configure -des -Dprefix="$prefix" -Duseshrplib=false
    case "$version" in
        3.*) printf '\n#define MKDIR 1\n#define RMDIR 1\n' >> config.h ;;
        4.*) printf '\n#define HAS_MKDIR 1\n#define HAS_RMDIR 1\n#define HAS_STRERROR 1\n' >> config.h ;;
    esac
    case "$version" in
        2.*|3.*|4.*)
            # shortcut: old makedepend is broken by modern shells; fresh builds do not need its incremental dependency rules.
            sed -i '/^# AUTOMATICALLY GENERATED MAKE DEPENDENCIES/,$d' Makefile
            ;;
        5.004_05|5.005_04) sed -i '/^# AUTOMATICALLY GENERATED MAKE DEPENDENCIES/,$d' x2p/Makefile ;;
    esac
    case "$version" in 2.*) make perly.h ;; esac
    case "$version" in
        1.*) make perl ;;
        2.*) make perl CFLAGS='-O0 -fcommon' libs='-lm -lcrypt' ;;
        3.*) make perl CFLAGS='-O0 -fcommon' libs='-lm -lcrypt' ;;
        4.*) make perl libs='-lm -lcrypt' ;;
        5.004_05|5.005_04) make -j 2 libs='-lm -lcrypt' ;;
        *) make -j "${BUILD_JOBS:-8}" ;;
    esac
    case "$version" in
        1.*|2.*|3.*|4.*)
            mkdir -p "$prefix/bin"
            cp perl "$prefix/bin/perl"
            [ ! -d lib ] || cp -R lib "$prefix/lib"
            ;;
        *) make install ;;
    esac
    "$prefix/bin/perl" -e 'print "ok\n";' | grep -qx ok
    cd /all-perl
    rm -rf "$source" "$archive"
done 3< versions.txt

if [ "$selection" != all ]; then
    for version in $selection; do
        [ -x "/opt/perls/$version/bin/perl" ] || { echo "version not built: $version" >&2; exit 1; }
    done
fi
