# $Id: /mirror/youri/soft/core/trunk/Makefile.PL 1284 2006-11-06T19:46:28.041137Z guillomovitch  $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Youri::Repository',
    VERSION_FROM => 'lib/Youri/Repository.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM  => {
        'base'                      => 0,
        'strict'                    => 0,
        'version'                   => 0,
        'warnings'                  => 0,
        'Carp'                      => 0,
        'File::Basename'            => 0,
        'File::Temp'                => 0,
        'List::UtilsBy'             => 0,
        'Youri::Package'            => 0,
    },
    TEST_REQUIRES  => {
        'Test::Kwalitee'            => 0,
        'Test::More'                => 0,
        'Youri::Package::RPM::Test' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/guillomovitch/Youri-Package.git',
                web  => 'https://github.com/guillomovitch/Youri-Package'
            },
        }
    }
);
