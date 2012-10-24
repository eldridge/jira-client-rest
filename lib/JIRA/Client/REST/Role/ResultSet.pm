package JIRA::Client::REST::Role::ResultSet;

use Moose::Role;

has shit => (is => 'ro', isa => 'Object');
has spore       => (is => 'ro', isa => 'Object',    lazy_build => 1);

sub iterator
{
	my $self = shift;

	new MooseX::Iterator::Array collection => $self->all;
}

sub all
{
	my $self = shift;

	#$self->spore->$method($self->context);
}

sub fetch
{
	my $self = shift;
}

sub create
{
	my $self = shift;
}

sub delete
{
	my $self = shift;

	$_->delete foreach $self->all
}

1;

