package Game::Battleship::Craft;
$VERSION = '0.0302';
use strict;
use warnings;
use Carp;

sub new {
    my ($proto, %args) = @_;
    my $class = ref ($proto) || $proto;

    # The name is a required attribute.
    croak "Craft name not provided.\n" unless defined $args{name};

    my $self = {
        # Who am I?
        id   => $args{id},
        name => $args{name},
        # Where's my bow (craft nose)?
        position => $args{position} || undef,
        # How much am I worth?
        points => $args{points} || undef,
        # How many times have I been hit?
        hits => $args{hits} || 0,
    };

    # Default the id to the upper-cased first char of name.
    $self->{id} = ucfirst substr $self->{name}, 0, 1
        unless defined $self->{id};

    bless $self, $class;
    return $self;
}

sub hit {
    my $self = shift;
    # Tally the hit.
    $self->{hits}++;
    # Hand back the remainder of the craft's value.
    return $self->{points} - $self->{hits};
}

1;

__END__

=head1 NAME

Game::Battleship::Craft - A Battleship craft class

=head1 SYNOPSIS

  use Game::Battleship::Craft;
  my $craft = Game::Battleship::Craft->new(
      id => 'T',
      name => 'tug boat',
      points => 1,
  )
  my $points_remaining = $craft->hit;

=head1 DESCRIPTION

A C<Game::Battleship::Craft> object represents the profile of a
Battleship

=head1 PUBLIC METHODS

=head2 B<new> %ARGUMENTS

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

Currently, the craft is assumed to have a horizontal or vertical
alignment.  Soon there will be diagonal positioning...

=back

=head2 B<hit()>

  $points_remaining = $craft->hit;

Increment the craft's C<hit> attribute value and return what's left of
the craft (total point value minus the number of hits).

=head1 TO DO

Have different numbers of different weapons.

Allow a craft to have a width.

Allow diagonal positions too.  Why not?

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

See L<Game::Battleship>.

=cut
