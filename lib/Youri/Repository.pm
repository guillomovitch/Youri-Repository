# $Id: Base.pm 631 2006-01-26 22:22:23Z guillomovitch $
package Youri::Repository;

=head1 NAME

Youri::Repository - Abstract repository

=head1 DESCRIPTION

This abstract class defines Youri::Repository interface.

=cut

use warnings;
use strict;
use Carp;
use Youri::Package;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Repository object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        install_root  => '', # path to top-level directory
        archive_root  => '', # path to top-level directory
        version_root  => '', # path to top-level directory
        test          => 0,  # test mode
        verbose       => 0,  # verbose mode
        @_
    );


    croak "no install root" unless $options{install_root};
    croak "invalid install root" unless -d $options{install_root};

    my $self = bless {
        _install_root  => $options{install_root},
        _archive_root  => $options{archive_root},
        _version_root  => $options{version_root},
        _test          => $options{test},
        _verbose       => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_older_revisions($package, $target, $define)

Get all older revisions from a package found in its installation directory, as a
list of C<Youri::Package> objects.

=cut

sub get_older_revisions {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package older revisions for $target\n"
        if $self->{_verbose} > 0;

    return $self->get_revisions(
        $package,
        $target,
        $define,
        sub { return $package->compare($_[0]) > 0 }
    );
}

=head2 get_last_older_revision($package, $target, $define)

Get last older revision from a package found in its installation directory, as a
single C<Youri::Package> object.

=cut

sub get_last_older_revision {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package last older revision for $target\n"
        if $self->{_verbose} > 0;

    return ($self->get_older_revisions($package, $target, $define))[0];
}

=head2 get_newer_revisions($package, $target, $define)

Get all newer revisions from a package found in its installation directory, as a
list of C<Youri::Package> objects.

=cut

sub get_newer_revisions {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package newer revisions for $target\n"
        if $self->{_verbose} > 0;

    return $self->get_revisions(
        $package,
        $target,
        $define,
        sub { return $_[0]->compare($package) > 0 }
    );
}


=head2 get_revisions($package, $target, $define, $filter)

Get all revisions from a package found in its installation directory, using an
optional filter, as a list of C<Youri::Package> objects.

=cut

sub get_revisions {
    my ($self, $package, $target, $define, $filter) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for package $package revisions for $target\n"
        if $self->{_verbose} > 0;

    my @packages = 
        map { $self->get_package_class()->new(file => $_) }
        $self->get_files(
            $self->{_install_root},
            $self->get_install_path($package, $target, $define),
            $self->get_package_class()->get_pattern($package->get_name())
        );

    @packages = grep { $filter->($_) } @packages if $filter;

    return
        sort { $b->compare($a) } # sort by revision order
        @packages;
}

=head2 get_obsoleted_packages($package, $target, $define)

Get all packages obsoleted by given one, as a list of C<Youri::Package>
objects.

=cut

sub get_obsoleted_packages {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for packages obsoleted by $package for $target\n"
        if $self->{_verbose} > 0;

    my @packages;
    foreach my $obsolete ($package->get_obsoletes()) {
        my $pattern = $self->get_package_class()->get_pattern($obsolete->[Youri::Package::DEPENDENCY_NAME]);
        push(@packages,
            map { $self->get_package_class()->new(file => $_) }
            $self->get_files(
                $self->{_install_root},
                $self->get_install_path($package, $target, $define),
                $pattern
            )
        );
    }

    return @packages;
}

=head2 get_replaced_packages($package, $target, $define)

Get all packages replaced by given one, as a list of C<Youri::Package>
objects.

=cut

sub get_replaced_packages {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for packages replaced by $package for $target\n"
        if $self->{_verbose} > 0;

    return 
        $self->get_older_revisions($package, $target, $define),
        $self->get_obsoleted_packages($package, $target, $define);
}

=head2 get_files($path, $pattern)

Get all files found in a directory, using an optional filtering pattern, as a
list of files.

=cut

sub get_files {
    my ($self, $root, $path, $pattern) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for files matching $pattern in $root/$path\n"
        if $self->{_verbose} > 1;

    my @files =
        grep { -f }
        glob "$root/$path/*";

    @files = grep { /$pattern/ } @files if $pattern;

    return @files;
}

=head2 get_install_root()

Returns installation root

=cut

sub get_install_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_install_root};
}

=head2 get_install_dir($package, $target, $define)

Returns install destination directory for given L<Youri::Package> object
and given target.

=cut

sub get_install_dir {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_install_root} .
        '/' .
        $self->get_install_path($package, $target, $define);
}

=head2 get_archive_root()

Returns archiving root

=cut

sub get_archive_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_archive_root};
}

=head2 get_archive_dir($package, $target, $define)

Returns archiving destination directory for given L<Youri::Package> object
and given target.

=cut

sub get_archive_dir {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_archive_root} .
        '/' .
        $self->get_archive_path($package, $target, $define);
}

=head2 get_version_root()

Returns versionning root

=cut

sub get_version_root {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_version_root};
}

=head2 get_version_dir($package, $target, $define)

Returns versioning destination directory for given L<Youri::Package>
object and given target.

=cut

sub get_version_dir {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_version_root} .
        '/' .
        $self->get_version_path($package, $target, $define);
}

=head2 get_install_file($package, $target, $define)

Returns install destination file for given L<Youri::Package> object and
given target.

=cut

sub get_install_file {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return 
        $self->get_install_dir($package, $target, $define) .
        '/' .
        $package->get_file_name();
}

=head2 get_package_class()

Return package class for this repository.

=head2 get_install_path($package, $target, $define)

Returns installation destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head2 get_archive_path($package, $target, $define)

Returns archiving destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head2 get_version_path($package, $target, $define)

Returns versioning destination path (relative to repository root) for given
L<Youri::Package> object and given target.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item get_install_path

=item get_archive_path

=item get_version_path

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
