package T6;
use Object::Simple;

sub build_m1 : Attr { auto_build => 1 }
sub build_build_m1{
    shift->build_m1( 1 );
}

Object::Simple->end;
