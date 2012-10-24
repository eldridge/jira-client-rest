package JIRA::Client::REST::Actor;

use Moose;
use MooseX::Storage;
use MooseX::Types::DateTime qw(DateTime Duration);

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id		=> (is => 'ro', isa => 'Int');
has name	=> (is => 'ro', isa => 'Str');
has type	=> (is => 'ro', isa => 'Str');

sub inflate
{
	my $self = shift;
	my $body = shift;

	my $href = { %$body };

	return $self->unpack($href, @_);
}

1;
