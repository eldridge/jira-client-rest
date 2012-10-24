package JIRA::Client::REST::ResultSet::Issues;

use Moose;

use SQL::Abstract;

use JIRA::Client::REST::Issue;

with 'JIRA::Client::REST::Role::ResultSet';

has sqla =>
	is		=> 'ro',
	isa		=> 'SQL::Abstract',
	default	=> sub { new SQL::Abstract };

has context =>
	is			=> 'ro',
	isa			=> 'Ref',
	predicate	=> 'has_context';

sub fetch
{
	my $self = shift;
	my $args = shift;

	return $self->single($args) if ref $args eq '';

	# chaining!
	$args = [ -and => [ $self->context, $args ] ] if $self->has_context;

	return new JIRA::Client::REST::ResultSet::Issues
		spore	=> $self->spore,
		context	=> $args;
}

sub single
{
	my $self	= shift;
	my $key		= shift;

	my $res = eval { $self->spore->get_issue(id => $key) };

	return $res
		? JIRA::Client::REST::Issue->inflate($res->{body}, inject => { spore => $self->spore })
		: undef;
}

sub all
{
	my $self = shift;

	my ($query, @params)	= $self->sqla->where($self->context);
	my @quoted				= map { s/"/\\"/g; "\"$_\""; } @params;

	$query =~ s/\?/shift @quoted/eg;
	$query =~ s/^\s*WHERE\s*//;

	my $res = $self->spore->search(payload => { jql => $query });

	return
		map { JIRA::Client::REST::Issue->inflate($_, inject => { spore => $self->spore }) }
		@{ $res->{body}->{issues} };
}

1;
