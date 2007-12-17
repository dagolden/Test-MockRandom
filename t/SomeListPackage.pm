package SomeListPackage;

sub new {
    my $class = shift;
    return bless( {}, ref($class) || $class );
}

# calls rand() with a list of 0's.  in list context, rand() will get 0.
# but in scalar context, rand() will get $limit.
sub list_random {
    my ($self, $limit) = @_;
    my @list;
    push(@list, 0) for(1..$limit);
    my $rnd = rand(@list);
    return $rnd;
}

1;
