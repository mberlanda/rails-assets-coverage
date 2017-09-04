package Rails::Assets {
  use 5.006;
  use strict;
  use warnings;

  use Rails::Assets::Base;
  use Rails::Assets::Processor;
  use Clone qw(clone);

  our $VERSION = '0.02';
  our $TEMPLATE_DIR = [qw( app/views/)];
  our $TEMPLATE_EXT = [qw(.haml .erb)];
  our $ASSETS_DIR = [qw( app/assets/ public/ vendor/assets/ )];
  our $ASSETS_EXT = {
    fonts => [qw(.woff2 .woff .ttf .eot .otf)],
    images => [qw(.png .jpg .gif .svg .ico)],
    javascripts => [qw(.js .map)],
    stylesheets => [qw(.css .scss)],
  };

  sub new {
    my $class = shift;
    my $self = {
      TEMPLATE_DIR => [@$Rails::Assets::TEMPLATE_DIR],
      TEMPLATE_EXT => [@$Rails::Assets::TEMPLATE_EXT],
      ASSETS_DIR => [@$Rails::Assets::ASSETS_DIR],
      ASSETS_EXT => {%$Rails::Assets::ASSETS_EXT},
    };
    bless $self, $class;
  }

  sub template_dir { $_[0]->{TEMPLATE_DIR} }
  sub template_ext { $_[0]->{TEMPLATE_EXT} }
  sub assets_dir { $_[0]->{ASSETS_DIR} }
  sub assets_ext { $_[0]->{ASSETS_EXT} }
  sub assets_hash { $_[0]->{ASSETS_HASH} }
  sub template_hash { $_[0]->{TEMPLATE_HASH} }
  sub scss_hash { $_[0]->{SCSS_HASH} }
  sub map_hash { $_[0]->{MAP_HASH} }
  sub assets_paths { $_[0]->{ASSETS_PATHS} }
  sub reversed_ext { $_[0]->{REVERSED_EXT} }

  sub analyse {
    my $self = shift;
    my ($assets_hash, $assets_paths, $reversed_ext) =
      prepare_assets_refs($self->assets_dir, $self->assets_ext);

    $self->{ASSETS_HASH} = clone($assets_hash);
    $self->{TEMPLATE_HASH} = clone($assets_hash);
    $self->{SCSS_HASH} = clone($assets_hash);
    $self->{MAP_HASH} = clone($assets_hash);
    $self->{ASSETS_PATHS} = $assets_paths;
    $self->{REVERSED_EXT} = {%$reversed_ext};

    process_asset_file($_, $self->{REVERSED_EXT}, $self->{ASSETS_HASH}, $self->{ASSETS_PATHS})
      foreach @{find_files($self->assets_dir())};
    process_template_file($_, $self->{TEMPLATE_HASH}, $self->template_ext())
      foreach @{find_files($self->template_dir())};

    my $scss_files = [grep { $_->{ext} eq '.scss' } @{$self->{ASSETS_HASH}->{stylesheets}}];
    my $js_files = [grep { $_->{ext} eq '.js' } @{$self->{ASSETS_HASH}->{javascripts}}];

    process_scss_file($_, $self->{REVERSED_EXT}, $self->{SCSS_HASH}) foreach map {$_->{full_path}} @{$scss_files};
    process_map_file($_, , $self->{REVERSED_EXT}, $self->{MAP_HASH}) foreach map {$_->{full_path}} @{$js_files};
    $self;
  }

}
=head1 NAME

Rails::Assets - provides some utilities functions for Assets detection in a Rails project.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module an object for parsing Assets directories

    use Rails::Assets;

    my $assets = Rails::Assets->new();

    my $template_directories = $assets->template_dir();
    my $template_extensions = $assets->template_ext();
    my $assets_directories = $assets->assets_dir();
    my $assets_extensions = $assets->assets_ext();

    $assets->analyse();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new
The constructor takes no argument for now. Later it would be interesting to add additional paths
and extensions. This would require some validation and it might have some side effects

=head2 template_dir
=head2 template_ext
=head2 assets_dir
=head2 assets_ext
=head2 assets_hash
=head2 template_hash
=head2 scss_hash
=head2 map_hash
=head2 assets_paths
=head2 reversed_ext
=head2 analyse

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rails-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rails-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rails::Assets

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rails-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rails-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rails-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/Rails-Assets/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mauro Berlanda.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Rails::Assets
