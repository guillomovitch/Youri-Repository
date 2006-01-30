# $Id: Base.pm 631 2006-01-26 22:22:23Z guillomovitch $
package Youri::Upload::Repository::Base;

=head1 NAME

Youri::Upload::Repository::Base - Abstract repository module class

=head1 DESCRIPTION

This abstract class defines Youri::Upload::Repository interface.

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Upload::Repository object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class   = shift;
    my %options = (
        path    => '', # path to top-level directory
        class   => '', # class to use for packages
        test    => 0,  # test mode
        verbose => 0,  # verbose mode
        @_
    );

    my $self = bless {
        _path    => $options{path},
        _class   => $options{class},
        _test    => $options{test},
        _verbose => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_older_releases($package, $target)

Get all older releases from a package found in its installation directory, as a
list of package objects.

=cut

sub get_older_releases {
    my ($self, $package, $target) = @_;

    return $self->get_releases(
        $package,
        $target,
        sub { return $package->compare_pkg($_[0]) > 0 }
    );
}

=head2 get_newer_releases($package, $target)

Get all newer releases from a package found in its installation directory, as a
list of package objects.

=cut

sub get_newer_releases {
    my ($self, $package, $target) = @_;

    return $self->get_releases(
        $package,
        $target,
        sub { return $_[0]->compare_pkg($package) > 0 }
    );
}

=head2 get_obsoleted_releases($package, $target)

Get all packages obsoleted by given one, as a list of C<Youri::Package::Base>
objects.

=cut

sub get_obsoleted_packages {
    my ($self, $package, $target) = @_;

    my @packages;
    foreach my $obsolete ($package->obsoletes()) {
        my $pattern = $self->{_class}->pattern($obsolete);
        push(@packages,
            map { $self->{_class}->new(file => $_) }
            $self->get_files(
                $self->destination_dir($package, $target),
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
    my ($self, $package, $target, $filter) = @_;

    my @packages = 
        map { $self->{_class}->new(file => $_) }
        $self->get_files(
            $self->destination_dir($package, $target),
            $self->{_class}->pattern($package->name())
        );

    @packages = grep { $filter->($_) } @packages if $filter;

    return
        sort { $b->compare_pkg($a) } # sort by release order
        @packages;
}

=head2 get_files($path, $pattern)

Get all files found in a directory, using an optional filtering pattern, as a
list of files.

=cut

sub get_files {
    my ($self, $path, $pattern) = @_;

    my @files =
        grep { -f }
        glob "$self->{_path}/$path/*";

    @files = grep { /$pattern/ } @files if $pattern;

    return @files;
}

=head2 destination_dir($package, $target)

Returns destination directory for given L<Youri::Package::Base> object and given target.

=cut

sub destination_dir {
    croak "Not implemented method";
}

=head2 destination_file($package, $target)

Returns destination file for given L<Youri::Package::Base> object and given target.

=cut

sub destination_file {
    my ($self, $package, $target) = @_;

    return 
        $self->destination_dir($package, $target) .
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
