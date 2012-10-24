package JIRA::Client::REST::ProjectRole;

use Moose;
use MooseX::Storage;
use MooseX::Types::DateTime qw(DateTime Duration);

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id			=> (is => 'ro', isa => 'Int');
has name		=> (is => 'ro', isa => 'Str');
has description	=> (is => 'ro', isa => 'Str');

has _actors =>
	is			=> 'ro',
	isa			=> 'ArrayRef[JIRA::Client::REST::Actor]',
	traits		=> [ 'Array' ],
	handles		=> {
		actors => 'elements'
	};

sub inflate
{
	my $self = shift;
	my $body = shift;

	my $href =
	{
		%$body,

		_actors => [ map { JIRA::Client::REST::Actor->inflate($_, @_) } @{ $body->{actors} } ]
	};

	return $self->unpack($href, @_);
}

1;
