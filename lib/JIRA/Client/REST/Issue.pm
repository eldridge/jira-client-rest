package JIRA::Client::REST::Issue;

use Moose;
use MooseX::Storage;
use MooseX::Types::DateTime qw(DateTime Duration);

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id			=> (is => 'ro', isa => 'Int');
has key			=> (is => 'ro', isa => 'Str');
has project		=> (is => 'ro', isa => 'JIRA::Client::REST::Project');
has type		=> (is => 'ro', isa => 'Str');
has summary		=> (is => 'ro', isa => 'Str');
has description	=> (is => 'ro', isa => 'Str');
has resolution	=> (is => 'ro', isa => 'Str');
has status		=> (is => 'ro', isa => 'JIRA::Client::REST::Status');

has _transitions =>
	is			=> 'ro',
	isa			=> 'HashRef[JIRA::Client::REST::Transition]',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> {
		get_transition		=> 'get',
		transitions			=> 'values',
		transition_names	=> 'keys'
	};

has links =>
	is	=> 'ro',
	isa	=> 'JIRA::Client::REST::Links';

has attachments =>
	is	=> 'ro',
	isa	=> 'ArrayRef[JIRA::Client::REST::Link]';

has watchers =>
	is	=> 'ro',
	isa	=> 'ArrayRef[JIRA::Client::REST::User]';

has comments =>
	is	=> 'ro',
	isa	=> 'ArrayRef[JIRA::Client::REST::IssueComment]';

has worklogs =>
	is	=> 'ro',
	isa	=> 'ArrayRef[JIRA::Client::REST::WorkLog]';

sub inflate
{
	shift->unpack(@_);
}

around unpack => sub
{
	my $orig = shift;
	my $self = shift;
	my $body = shift;
	my $args = { @_ };

	my $href =
	{
		id			=> $body->{id},
		key			=> $body->{key},
		type		=> $body->{fields}->{issuetype}->{name},
		summary		=> $body->{fields}->{summary},
		description	=> $body->{fields}->{description}
	};

	# XXX: this inject_spawn business has some putrid codesmell
	$self->inject_spawn($args, status => Status => $body->{fields}->{status});

	$self->$orig($href, %$args);

};

sub _build__transitions
{
	my $self = shift;

	my $res = $self->spore->get_issue_transitions(id => $self->id);

	my @transitions = map { $self->spawn(Transition => $_) } @{ $res->{body}->{transitions} };

	return { map { $_->name => $_ } @transitions };
}

sub is_closed { return shift->status->name eq 'Closed' }

method transition (Str :$name, Str :$to)
{
	die "specify a transition name or a destination status, not both" if $name and $to;

	my $transition = undef;

	if ($name) {
		$transition = $self->get_transition($name)
			or die "unknown transition '$name'";
	} else {
		my @transitions = grep { $_->destination->name eq $to } $self->transitions;

		die "unable to find a transition with a destination status of '$to'" if not scalar @transitions;
		die "unable to find a unique transition with a destination status of '$to'" if scalar @transitions > 1;

		$transition = pop @transitions;
	}

	$self->spore->transition(id => $self->id, payload => { transition => { id => $transition->id } });
	$self->_clear_transitions;
}

method add_worklog (Str :$comment!, DateTime :$started!, DateTime :$stopped, DateTime::Duration :$duration)
{
	my $fmt = new DateTime::Format::Duration pattern => '%Hh %Mm';

	die 'both stop time and duration specified; only one is needed'
		 if $stopped and $duration;
	die 'stop time or duration required'
		 if not $stopped and not $duration;

	$duration = $stopped - $started if $stopped and not $duration;

	my $params =
	{
		id				=> $self->id,
		adjustEstimate	=> 'leave',
		payload			=>
		{
			comment		=> $comment,
			started		=> $started->strftime('%FT%T.%3N%z'),
			timeSpent	=> $fmt->format_duration($duration)
		}
	};

	try {
		$self->spore->add_worklog(%$params);
	} catch {
		use Data::Dump;
		dd $_;
		die $_;
	}
}

sub add_comment
{
}

sub add_watcher
{
}

sub remove_watcher
{
}

1;
