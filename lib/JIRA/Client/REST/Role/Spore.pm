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
	my $type = shift;
	my $data = shift;

	die 'spawn may not be called statically' if not ref $self;

	my $class = "JIRA::Client::REST::$type";

	$class->inflate($data, inject => { spore => $self->spore });
}

sub inject_spawn
{
	my $self	= shift;
	my $args	= shift;
	my $key		= shift;
	my $type	= shift;
	my $data	= shift;

	my $class = "JIRA::Client::REST::$type";

	$args->{inject}->{$key} = $class->inflate($data, inject => { spore => $args->{inject}->{spore} });
}

1;

