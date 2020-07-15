package Game::Battleship::Craft;

use Carp;
use Moo;
use Types::Standard qw( ArrayRef Int Num Str );

has id => (
    is  => 'ro',
    isa => Str,
);

has name => (
    is  => 'ro',
    isa => Str,
);

has position => (
    is  => 'ro',
    isa => ArrayRef[Num],
);

has points => (
    is  => 'ro',
    isa => Int,
);

has hits => (
    is  => 'ro',
    isa => Int,
);

sub BUILD {
    my $self = shift;
    # Default the id to the upper-cased first char of name.
    unless ( $self->id ) {
        $self->{id} = ucfirst substr( $self->{name}, 0, 1 );
    }
}

sub hit {
    my $self = shift;
    # Tally the hit.
    $self->{hits}++;
    # Hand back the remainder of the craft's value.
    return $self->points - $self->hits;
}

1;

__END__

=head1 SYNOPSIS

  use Game::Battleship::Craft;
  my $craft = Game::Battleship::Craft->new(
      id => 'T',
      name => 'tug boat',
      points => 1,
  )
  my $points_remaining = $craft->hit;

=head1 DESCRIPTION

A C<Game::Battleship::Craft> object represents the profile of a Battleship craft.

=head1 PUBLIC METHODS

=head2 new

=over 4

=item * id => $STRING

A scalar identifier to use to indicate position on the grid.  If one
is not provided, the upper-cased first name character will be used by
default.

Currently, it is required that this be a single uppercase letter (the
first letter of the craft name, probably), since a C<hit> will be
indicated by "lower-casing" this mark on a player grid.

=item * name => $STRING

A required attribute provided to give the craft a name.

=item * points => $NUMBER

An attribute used to define the line segment span on the playing grid.

=item * position => [$X, $Y]

The position of the craft bow ("nose") on the grid.

The craft is assumed to have a horizontal or vertical alignment.

=item * hits => $NUMBER

Computed

=back

=for Pod::Coverage BUILD

=head2 hit

  $points_remaining = $craft->hit;

Increment the craft's C<hit> attribute value and return what's left of
the craft (total point value minus the number of hits).

=head1 TO DO

Have different numbers of different weapons.

Allow a craft to have a width.

=cut
