package Game::Battleship::Player;
use strict;
use warnings;
use Carp;
use Game::Battleship::Craft;
use Game::Battleship::Grid;

sub new {
    my ($proto, %args) = @_;
    my $class = ref ($proto) || $proto;

    my $self = {
        id    => $args{id}    || undef,
        name  => $args{name}  || undef,
        score => $args{score} || 0,
        life  => $args{life}  || 0,
        fleet => $args{fleet} || [
            Game::Battleship::Craft->new(
                name   => 'aircraft carrier',
                points => 5,
            ),
            Game::Battleship::Craft->new(
                name   => 'battleship',
                points => 4,
            ),
            Game::Battleship::Craft->new(
                name   => 'cruiser',
                points => 3,
            ),
            Game::Battleship::Craft->new(
                name   => 'submarine',
                points => 3,
            ),
            Game::Battleship::Craft->new(
                name   => 'destroyer',
                points => 2,
            ),
        ],
    };

    bless $self, $class;
    $self->_init(\%args);
    return $self;
}

sub _init {
    my ($self, $args) = @_;

    # Initialize a grid and place the player's fleet, if one is
    # provided.
    $self->{grid} = Game::Battleship::Grid->new(
        fleet => $self->{fleet},
        dimensions => $args->{dimensions},
    );

    # Compute the life points for this player.
    $self->{life} += $_->{points} for @{ $self->{fleet} };
}

sub name { return shift->{name} }

# The enemy must be a G::B::Player object.
sub grid {
    my ($self, $enemy) = @_;
    return $enemy
        ? join "\n",
            map { "@$_" } @{ $self->{$enemy->{name}}{matrix} }
        : join "\n",
            map { "@$_" } @{ $self->{grid}{matrix} };
}

# The enemy must be a G::B::Player object.
sub strike {
    my ($self, $enemy, $x, $y) = @_;

    croak "No opponent to strike.\n" unless $enemy;
    croak "No coordinate at which to strike.\n"
        unless defined $x && defined $y;

    if ($enemy->{life} > 0) {
        # Initialize the enemy grid map if we need to.
        $self->{$enemy->{name}} = Game::Battleship::Grid->new
            unless exists $self->{$enemy->{name}};

        my $enemy_pos = \$enemy->{grid}{matrix}[$x][$y];
        my $map_pos   = \$self->{$enemy->{name}}{matrix}[$x][$y];

        if ($$map_pos ne '.') {
            warn "Duplicate strike on $enemy->{name} by $self->{name} at $x, $y.\n";
            return -1;
        }
        elsif ($enemy->_is_a_hit($x, $y)) { # Set the enemy grid map coordinate char to 'hit'.
            $$map_pos = 'x';

            # What craft was hit?
            my $craft = $self->craft(id => $$enemy_pos);

            warn "$self->{name} hit $enemy->{name}'s $craft->{name}!\n";

            # How much is left on this craft?
            my $remainder = $craft->hit;

            # Tally the hit in the craft object, itself and emit a happy
            # warning if it was totally destroyed.
            warn "$self->{name} sunk $enemy->{name}'s $craft->{name}!\n"
                unless $remainder;

            # Indicate the hit on the enemy grid by lowercasing the craft
            # id.
            $$enemy_pos = lc $$enemy_pos;

            # Increment the player's score.
            $self->{score}++;

            # Decrement the opponent's life.
            warn "$enemy->{name} is out of the game.\n"
                if --$enemy->{life} <= 0;

            return 1;
        }
        else {
            # Set the enemy grid map coordinate char to 'miss'.
            warn "$self->{name} missed $enemy->{name} at $x, $y.\n";
            $$map_pos = 'o';
            return 0;
        }
    }
    else {
        warn "$enemy->{name} is already out of the game. Strike another opponent.\n";
        return -1;
    }
}

sub _is_a_hit {
    my ($self, $x, $y) = @_;
    return $self->{grid}{matrix}[$x][$y] ne '.'
        ? 1 : 0;
}

sub craft {
    my ($self, $key, $val) = @_;

    # If the key is not defined, assume it's supposed to be the id.
    unless (defined $val) {
        $val = $key;
        $key = 'id';
    }

    my $craft;

    for (@{ $self->{fleet} }) {
        if ($val eq $_->{$key}) {
            $craft = $_;
            last;
        }
    }

    return $craft;
}

1;

__END__

=head1 NAME

Game::Battleship::Player - A Battleship player class

=head1 SYNOPSIS

  use Game::Battleship::Player;
  my $aaron = Game::Battleship::Player->new(name => 'Aaron');
  my $gene  = Game::Battleship::Player->new(name => 'Gene');
  print 'Player 1: ', $aaron->name, "\n",
        'Player 2: ', $gene->name,  "\n";
  $aaron->strike($gene, 0, 0);
  # Repeat and get a duplicate strike warning.
  my $strike = $aaron->strike($gene, 0, 0);
  print $aaron->grid($gene), "\nThat was a " .
    ( $strike == 1 ? 'hit!'
    : $strike == 0 ? 'miss.'
                   : 'duplicate?' ), "\n";
  my $craft_obj = $aaron->craft($id);

=head1 DESCRIPTION

A C<Game::Battleship::Player> object represents a Battleship player
complete with fleet and game surface.

=head1 PUBLIC METHODS

=over 4

=item B<new> %ARGUMENTS

  $player => Game::Battleship::Player->new(
      name  => 'Aaron',
      fleet => \@fleet,
      dimensions => [$x, $y],
  );

=over 4

=item * name => $STRING

An optional attribute provided to give the player a name.

If not provided, the string "player_1" or "player_2" is used.

=item * fleet => [$CRAFT_1, $CRAFT_2, ... $CRAFT_N]

Array reference of C<Game::Battleship::Craft> objects.

If not explicitly provided, the standard fleet (with 5 ships) is
created by default.

=item * dimensions => [$WIDTH, $HEIGHT]

Array reference with the player's grid height and width values.

If the grid dimensions are not explicitly specified, the standard
ten by ten grid is used.

=back

=item B<grid>

  $grid = $player->grid();
  $grid = $player->grid($enemy);

Return the playing grid as a "flush-left" text matrix like this:

  . . . . . . . . . .
  . . . . . . . . . .
  . . . . . . . . . .
  . . . S S S . . . .
  . . . . . . C . . .
  . . . . . A C . . .
  . D . . . A C . . B
  . D . . . A . . . B
  . . . . . A . . . B
  . . . . . A . . . B

Eventually, this method will respect the game type and return an
appropriate representation, such as a PNG file or XML, etc.

=item B<strike> $PLAYER, @COORDINATE

  $strike = $player->strike($enemy, $x, $y);

Strike the enemy at the given coordinate and return a numeric value
to indicate success or failure.

The player to strike must be given as a C<Game::Battleship::Player>
object and the coordinate must be given as a numeric pair.

On success, an "x" is placed on the striking player's "opponent map
grid" (a C<Game::Battleship::Grid> object attribute named for the
opponent) at the given coordinate, the opponent's "craft grid" is
updated by lower-casing the C<Game::Battleship::Craft> object C<id>
at the given coordinate, the opponent C<Game::Battleship::Craft>
object C<hits> attribute is incremented, the striking player's
C<score> attribute is incremented, and a one (i.e. true) is returned.

If an enemy craft is completely destroyed, a happy warning is emitted.

On failure, an "o" is placed on the striking player's "opponent map
grid" at the given coordinate and a zero (i.e. false) is returned.

If a player calls for a strike at a coordinate that was already
struck, a warning is emitted and a negative one (-1) is returned.

=item B<craft> $KEY [$VALUE]

  $craft = $player->craft($id);
  $craft = $player->craft(id => $id);
  $craft = $player->craft(name => $name);

Return the player's C<Game::Battleship::Craft> object that matches
the given argument(s).

If the last argument is not provided the first argument is assumed to
be the C<id> attribute.

=back

=head1 PRIVATE METHODS

=over 4

=item B<_is_a_hit> @COORDINATE

Return true or false if another player's strike is successful.  That
is, return a one if there is a craft at the given coordinate and zero
otherwise.

=back

=head1 TO DO

Include a weapon argument in the C<strike> method.

Make the C<grid> method honor the game type and return something
appropriate.

=head1 SEE ALSO

L<Game::Battleship>,
L<Game::Battleship::Craft>,
L<Game::Battleship::Grid>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

See L<Game::Battleship>.

=cut
