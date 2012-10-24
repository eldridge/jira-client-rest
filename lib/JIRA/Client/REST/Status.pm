package JIRA::Client::REST::Status;

use Moose;
use MooseX::Storage;

use Method::Signatures;

use Try::Tiny;

with Storage(format => 'JSON', io => 'File');

with 'JIRA::Client::REST::Role::Spore';

has id			=> (is => 'ro', isa => 'Int');
has name		=> (is => 'ro', isa => 'Str');
has description	=> (is => 'ro', isa => 'Str');
has icon		=> (is => 'ro', isa => 'URI');

1;
