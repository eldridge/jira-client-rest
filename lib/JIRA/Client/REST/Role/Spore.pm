package JIRA::Client::REST::Role::Spore;

use Moose::Role;

has spore => (is => 'ro', isa => 'Object', required => 1);

# XXX: use around(unpack) method modifier instead of this inflate method

sub inflate
{
	my $self = shift;
	my $body = shift;

	my $href = { %$body };

	return $self->unpack($href, @_);
}

sub spawn
{
	my $self = shift;
	my $name = shift;
	my $data = shift;

	my $class = "JIRA::Client::REST::$name";

	$class->inflate($data, inject => { spore => $self->spore });
}

1;

