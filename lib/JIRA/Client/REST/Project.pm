package JIRA::Client::REST::Project;

use Moose;
use MooseX::Storage;
use MooseX::Types::DateTime qw(DateTime Duration);

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id			=> (is => 'ro', isa => 'Int');
has key			=> (is => 'ro', isa => 'Str');
has name		=> (is => 'ro', isa => 'Str');
has description	=> (is => 'ro', isa => 'Str');
has lead		=> (is => 'ro', isa => 'Str');

has _components =>
	is			=> 'ro',
	isa			=> 'HashRef[JIRA::Client::REST::Component]',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> {
		get_component_by_name	=> 'get',
		get_component_names		=> 'keys',
		components				=> 'values'
	};

has _issue_types =>
	is			=> 'ro',
	isa			=> 'HashRef[JIRA::Client::REST::IssueType]',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> {
		get_issue_type_by_name	=> 'get',
		get_issue_type_names	=> 'keys',
		issue_types				=> 'values'
	};

has _roles =>
	is			=> 'ro',
	isa			=> 'HashRef[JIRA::Client::REST::ProjectRole]',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> {
		get_role_by_name	=> 'get',
		get_role_names		=> 'keys',
		roles				=> 'values'
	};

sub inflate
{
	my $self = shift;
	my $body = shift;

	use Data::Dump;

	my $href =
	{
		lead => $body->{lead}->{name},

		map { $_ => $body->{$_} } qw(id key name description)
	};

	return $self->unpack($href, @_);
}

sub _build__transitions
{
	my $self = shift;

	my $res = $self->spore->get_issue_transitions(id => $self->id);

	return { map { $_->{name} => $_->{id} } @{ $res->{body}->{transitions} } };
}

sub _build__components
{
	die 'Not Yet Implemented';
}

sub _build__issue_types
{
	die 'Not Yet Implemented';
}

sub _build__roles
{
	my $self = shift;

	my $res		= $self->spore->get_project_roles(key => $self->key);
	my $roles	= {};

	foreach my $name (keys %{ $res->{body} }) {
		if (my ($id) = ($res->{body}->{$name} =~ /role\/([0-9]+)$/)) {
			my $res = $self->spore->get_project_role(key => $self->key, id => $id);

			$roles->{$name} = JIRA::Client::REST::ProjectRole->inflate($res->{body}, inject => { spore => $self->spore });
		}
	}

	return $roles;
}

1;
