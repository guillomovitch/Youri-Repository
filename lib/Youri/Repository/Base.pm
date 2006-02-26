# $Id: Base.pm 631 2006-01-26 22:22:23Z guillomovitch $
package Youri::Repository::Base;

=head1 NAME

Youri::Repository::Base - Abstract repository module class

=head1 DESCRIPTION

This abstract class defines Youri::Upload::Repository interface.

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Repository object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class   = shift;
    my %options = (
        path          => '', # path to top-level directory
        package_class => '', # class to use for packages
        test          => 0,  # test mode
        verbose       => 0,  # verbose mode
        @_
    );

    my $self = bless {
        _path          => $options{path},
        _package_class => $options{package_class},
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

=head2 package_class()

Return package class for this repository.

=cut

sub package_class {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_package_class};
}


=head2 get_older_releases($package, $target)

Get all older releases from a package found in its installation directory, as a
list of package objects.

=cut

sub get_older_releases {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return $self->get_releases(
        $package,
        $target,
        $define,
        sub { return $package->compare($_[0]) > 0 }
    );
}

=head2 get_last_older_release($package, $target)

Get last older release from a package found in its installation directory, as a
single package object.

=cut

sub get_last_older_release {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return ($self->get_older_releases($package, $target, $define))[0];
}

=head2 get_newer_releases($package, $target)

Get all newer releases from a package found in its installation directory, as a
list of package objects.

=cut

sub get_newer_releases {
    my ($self, $package, $target, $define) = @_;

    return $self->get_releases(
        $package,
        $target,
        $define,
        sub { return $_[0]->compare($package) > 0 }
    );
}

=head2 get_obsoleted_releases($package, $target)

Get all packages obsoleted by given one, as a list of C<Youri::Package::Base>
objects.

=cut

sub get_obsoleted_packages {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    my @packages;
    foreach my $obsolete ($package->obsoletes()) {
        my $pattern = $self->{_package_class}->pattern($obsolete);
        push(@packages,
            map { $self->{_package_class}->new(file => $_) }
            $self->get_files(
                $self->get_internal_destination_dir($package, $target, $define),
                $pattern
            )
        );
    }

    return @packages;
}

=head2 get_releases($package, $filter)

Get all releases from a package found in its installation directory, using an
optional filter, as a list of package objects.

=cut

sub get_releases {
    my ($self, $package, $target, $define, $filter) = @_;
    croak "Not a class method" unless ref $self;

    my @packages = 
        map { $self->{_package_class}->new(file => $_) }
        $self->get_files(
            $self->get_internal_destination_dir($package, $target, $define),
            $self->{_package_class}->pattern($package->name())
        );

    @packages = grep { $filter->($_) } @packages if $filter;

    return
        sort { $b->compare($a) } # sort by release order
        @packages;
}

=head2 get_files($path, $pattern)

Get all files found in a directory, using an optional filtering pattern, as a
list of files.

=cut

sub get_files {
    my ($self, $path, $pattern) = @_;
    croak "Not a class method" unless ref $self;
    print "Looking for files in $self->{_path}/$path\n" if $self->{_test};

    my @files =
        grep { -f }
        glob "$self->{_path}/$path/*";

    @files = grep { /$pattern/ } @files if $pattern;

    return @files;
}

=head2 get_destination_dir($package, $target)

Returns destination directory for given L<Youri::Package::Base> object and given target.

=cut

sub get_destination_dir {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_path} .
        '/' .
        $self->get_internal_destination_dir($package, $target, $define);
}

=head2 get_destination_file($package, $target)

Returns destination file for given L<Youri::Package::Base> object and given target.

=cut

sub get_destination_file {
    my ($self, $package, $target, $define) = @_;
    croak "Not a class method" unless ref $self;

    return 
        $self->get_destination_dir($package, $target, $define) .
        '/' .
        $package->filename();
}

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item destination

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
