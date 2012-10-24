package JIRA::Client::REST;

# ABSTRACT: JIRA REST Client

use Moose;

use MooseX::Types::URI qw(Uri);

use Net::HTTP::Spore;
use File::ShareDir::PathClass;

use JIRA::Client::REST::Actor;
use JIRA::Client::REST::Issue;
use JIRA::Client::REST::Project;
use JIRA::Client::REST::ProjectRole;
use JIRA::Client::REST::Status;
use JIRA::Client::REST::Transition;

use JIRA::Client::REST::ResultSet::Issues;

=head1 DESCRIPTION

JIRA::Client::REST is a wrapper for the L<JIRA REST API|http://docs.atlassian.com/jira/REST/latest/>.

=head1 SYNOPSIS

    use JIRA::Client::REST;

    my $client = JIRA::Client::REST->new(
        username => 'username',
        password => 'password',
        url => 'http://jira.mycompany.com',
    );
    my $issue = $client->get_issue('TICKET-12');
    print $issue->{fields}->{priority}->{value}->{name}."\n";

=cut

has username	=> (is => 'rw', isa => 'Str',		required => 1);
has password	=> (is => 'rw', isa => 'Str',		required => 1);
has uri			=> (is => 'rw', isa => Uri,			required => 1, coerce => 1);
has debug		=> (is => 'rw', isa => 'Bool',		default => 0);
has spore		=> (is => 'ro', isa => 'Object',	lazy_build => 1);

has issues =>
	is			=> 'ro',
	isa			=> 'JIRA::Client::REST::ResultSet::Issues',
	lazy_build	=> 1;

sub _build_issues
{
	new JIRA::Client::REST::ResultSet::Issues spore => shift->spore;
}

sub _build_spore
{
	my $self = shift;

	my $share = eval { File::ShareDir::PathClass::dist_dir('JIRA-Client-REST') }
		|| new Path::Class::Dir;

	my $spec = $share->file('jira.spore');

	die "unable to locate SPORE specification file: $@" if not $spec;

	my $spore = Net::HTTP::Spore->new_from_spec($spec, base_url => $self->uri);

	$spore->enable('Format::JSON');
	$spore->enable('Auth::Basic', username => $self->username, password => $self->password);

	return $spore;
}

sub get_project
{
	my $self = shift;

	my $params	= { (scalar @_ > 1) ? (@_) : (key => shift) };
	my $res		= $self->spore->get_project(%$params);

	return JIRA::Client::REST::Project->inflate($res->{body}, inject => { spore => $self->spore });
}


########################################################################
## OLD METHODS #########################################################
########################################################################

=method get_issue($id, $expand)

Get the issue with the supplied id.  Returns a HashRef of data.

=cut

sub get_issue {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue(id => $id, expand => $expand);
}

=method get_issue_transitions($id, $expand)

Get the transitions possible for this issue by the current user.

=cut

sub get_issue_transitions {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_transitions(id => $id, expand => $expand);
}

=method get_issue_votes($id, $expand)

Get voters on the issue.

=cut

sub get_issue_votes {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_votes(id => $id, expand => $expand);
}

=method get_issue_watchers($id, $expand)

Get watchers on the issue.

=cut

sub get_issue_watchers {
    my ($self, $id, $expand) = @_;

    return $self->_client->get_issue_watchers(id => $id, expand => $expand);
}

=method get_project_versions($key)

Get the versions for the project with the specified key.

=cut

sub get_project_versions {
    my ($self, $key) = @_;
    
    return $self->_client->get_project_versions(key => $key);
}

=method get_version($id)

Get the version with the specified id.

=cut

sub get_version {
    my ($self, $id) = @_;
    
    return $self->_client->get_version(id => $id);
}

=method unvote_for_issue($id)

Remove your vote from an issue.

=cut

sub unvote_for_issue {
    my ($self, $id) = @_;

    return $self->_client->unvote_for_issue(id => $id);
}

=method unwatch_issue($id, $username)

Remove a watcher from an issue.

=cut

sub unwatch_issue {
    my ($self, $id, $username) = @_;

    return $self->_client->unwatch_issue(id => $id, username => $username);
}

=method vote_for_issue($id)

Cast your vote in favor of an issue.

=cut

sub vote_for_issue {
    my ($self, $id) = @_;

    return $self->_client->vote_for_issue(id => $id);
}

=method watch_issue($id, $username)

Watch an issue. (Or have someone else watch it.)

=cut

sub watch_issue {
    my ($self, $id, $username) = @_;

    return $self->_client->watch_issue(id => $id, username => $username);
}

1;
