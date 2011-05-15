#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 10;
use Youri::Package::RPM::Test;

BEGIN {
    use_ok('Youri::Repository::Test');
}

my $repository = Youri::Repository::Test->new(
    cleanup => 0,
    extra_arches => [ 'i586' ]
);
isa_ok($repository, 'Youri::Repository::Test');

my $foo1 = Youri::Package::RPM::Test->new(tags => {
    name => 'foo', version => 1, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($foo1)
    ],
    [ ],
    'first package release replaces nothing'
);

my $dir = $repository->get_install_dir($foo1);
my $foo1_path = $dir . '/' . $foo1->get_tag('filename');
system("touch $foo1_path");

my $foo2 = Youri::Package::RPM::Test->new(tags => {
    name => 'foo', version => 2, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($foo2)
    ],
    [ $foo1_path ],
    'second package release replaces first one'
);
my $foo2_path = $dir . '/' . $foo2->get_tag('filename');
system("touch $foo2_path");

my $foo3 = Youri::Package::RPM::Test->new(tags => {
    name => 'foo', version => 3, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($foo3)
    ],
    [ $foo2_path, $foo1_path ],
    'third package release replaces first ones'
);

my $libfoo1 = Youri::Package::RPM::Test->new(tags => {
    name => 'libfoo1', version => 1, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($libfoo1)
    ],
    [ ],
    'first libified package release replaces nothing'
);

my $libfoo1_path = $dir . '/' . $libfoo1->get_tag('filename');
system("touch $libfoo1_path");
my $libfoo2 = Youri::Package::RPM::Test->new(tags => {
    name => 'libfoo2', version => 2, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($libfoo2)
    ],
    [ ],
    'second libified package release replaces nothing'
);

my $libfoo2_path = $dir . '/' . $libfoo2->get_tag('filename');
system("touch $libfoo2_path");
my $libfoo3 = Youri::Package::RPM::Test->new(tags => {
    name => 'libfoo3', version => 3, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($libfoo3)
    ],
    [ ],
    'third libified package release replaces nothing'
);

my $noarchfoo4 = Youri::Package::RPM::Test->new(tags => {
    name => 'foo', version => 4, release => 1, arch => 'noarch'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($noarchfoo4)
    ],
    [ $foo2_path, $foo1_path ],
    'noarch package replaces i586 ones'
);

my $noarchfoo4_path = $dir . '/' . $noarchfoo4->get_tag('filename');
system("touch $noarchfoo4_path");

my $foo5 = Youri::Package::RPM::Test->new(tags => {
    name => 'foo', version => 5, release => 1, arch => 'i586'
});
is_deeply(
    [
        map { $_->as_file() }
        $repository->get_replaced_packages($foo5)
    ],
    [ $noarchfoo4_path, $foo2_path, $foo1_path ],
    'fifth package replaces all the ones with same name'
);
