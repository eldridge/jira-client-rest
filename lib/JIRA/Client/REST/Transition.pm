package JIRA::Client::REST::Transition;

use Moose;
use MooseX::Storage;
use MooseX::Types::DateTime qw(DateTime Duration);

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id			=> (is => 'ro', isa => 'Int');
has name		=> (is => 'ro', isa => 'Str');
has destination	=> (is => 'rw', isa => 'JIRA::Client::REST::Status');

around inflate => sub
{
	my $orig = shift;
	my $self = shift;
	my $body = shift;

	my $transition = $self->$orig($body, @_);

	$transition->destination($transition->spawn(Status => $body->{to}));

	return $transition;
};

1;
