use strict;
use warnings;
package Dist::Zilla::App::Command::listdeps;
use Dist::Zilla::App -command;
# ABSTRACT: print your distribution's prerequisites

=head1 SYNOPSIS

  $ dzil listdeps | cpan

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<listdeps>
command, which prints your distribution's prerequisites. You could pipe that
list to a CPAN client like L<cpan> to install all of the dependecies in one
quick go. This will include author dependencies (those listed under
C<develop_requires>) if the C<--author> flag is passed.

=head1 ACKNOWLEDGEMENTS

This code is more or less a direct copy of Marcel Gruenauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=cut

use Moose::Autobox;
use Version::Requirements;

sub abstract { "print your distribution's prerequisites" }

sub opt_spec {
  [ 'author', 'include author dependencies' ],
}

sub extract_dependencies {
  my ($self, $zilla, $phases) = @_;

  $_->before_build for $zilla->plugins_with(-BeforeBuild)->flatten;
  $_->gather_files for $zilla->plugins_with(-FileGatherer)->flatten;
  $_->prune_files  for $zilla->plugins_with(-FilePruner)->flatten;
  $_->munge_files  for $zilla->plugins_with(-FileMunger)->flatten;
  $_->register_prereqs for $zilla->plugins_with(-PrereqSource)->flatten;

  my $req = Version::Requirements->new;
  my $prereqs = $zilla->prereqs;

  for my $phase (@$phases) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') );
  }

  return sort { lc $a cmp lc $b } grep { $_ ne 'perl' } $req->required_modules;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->app->chrome->logger->mute;

  my @phases = qw(build test configure runtime);
  push @phases, 'develop' if $opt->author;

  print "$_\n" for $self->extract_dependencies($self->zilla, \@phases);
}

1;
