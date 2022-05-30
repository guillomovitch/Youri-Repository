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
    }
);

sub MY::postamble {
   return <<'EOF';
.PHONY: svntag
SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/Repository

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)

EOF
}
