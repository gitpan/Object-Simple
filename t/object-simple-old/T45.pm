package T45;
use Object::Simple::Old(base => 'T45_Base', mixins => [qw/T45_Mixin T45_Mixin2/]);

sub m6 {
    my $self = shift;
    return $self->call_super('m6', @_);
}
Object::Simple::Old->build_class;


