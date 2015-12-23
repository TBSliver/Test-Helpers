package Test::CGIBin;

use Moo;

use Plack::App::CGIBin;
use Plack::Builder;

use LWP::Protocol::PSGI;
use Test::WWW::Mechanize;

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::More;
  use Test::CGIBin;

  my $framework = Test::CGIBin->new(
    cgi_bin => "/path/to/cgi-bin",
    mount   => "/cgi-bin/test",
  );

  $framework->mech->get_ok( "http://localhost/cgi-bin/test/cgi-script.pl" );

  done_testing;

=head1 DESCRIPTION

This module creates a testframework, using Plack::App::CGIBin, and
Test::WWW::Mechanize. This gives you access to all the files in the cgi_bin
directory you specify, under the path you specify.

=cut

has 'cgi_bin' => (
  is => 'ro',
  required => 1,
  isa => sub {
    die "$_[0] is not a directory!" unless -d $_[0];
  },
);

has 'mount' => (
  is => 'ro',
  default => '/',
);

has exec_cb => (
  is => 'ro',
  default => sub {
    sub { 1 },
  },
);

has 'plack_cgibin' => (
  is => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    my $app = Plack::App::CGIBin->new(
      root    => $self->cgi_bin,
      exec_cb => $self->exec_cb,
    )->to_app;
    return $app;
  },
);

has 'plack_builder' => (
  is => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    my $builder = Plack::Builder->new;
    $builder->mount( $self->mount => $self->plack_cgibin );
    return $builder->to_app;
  },
);

has 'mech' => (
  is => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    LWP::Protocol::PSGI->register( $self->plack_builder );
    my $mech = Test::WWW::Mechanize->new;
    return $mech;
  },
);

1;
