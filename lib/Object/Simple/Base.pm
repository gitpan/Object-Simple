package Object::Simple::Base;
use strict;
use warnings;

use Object::Simple::Accessor qw/attr class_attr hybrid_attr/;

use base 'Exporter';
our @EXPORT_OK = ('new');

sub new {
    my $class = shift;

    # Instantiate
    return bless
      exists $_[0] ? exists $_[1] ? {@_} : {%{$_[0]}} : {},
      ref $class || $class;
}

=head1 NAME

Object::Simple::Base - a base class to provide constructor and accessors

=head1 SYNOPSIS
    
    package Book;
    use base 'Object::Simple::Base';
 
    __PACKAGE__->attr('title');
    __PACKAGE__->attr('pages' => 159);
    __PACKAGE__->attr([qw/authors categories/] => sub { [] });
    
    __PACKAGE__->class_attr('aaa');
    __PACKAGE__->hybrid_attr('bbb');
 
    package main;
    use Book;
 
    my $book = Book->new;
    print $book->pages;
    print $book->pages(5)->pages;
 
    my $my_book = Car->new(title => 'Good Day');
    print $book->authors(['Ken', 'Tom'])->authors;

=head1 Methods

=head2 new

A subclass of Object::Simple can call "new", and create a instance.
"new" can receive hash or hash ref.

    package Book;
    use base 'Object::Simple::Base';
    
    package main;
    my $book = Book->new;
    my $book = Book->new(title => 'Good day');
    my $book = Book->new({name => 'Good'});

"new" can be overrided to arrange arguments or initialize instance.

Arguments arrange
    
    sub new {
        my ($class, $title, $author) = @_;
        
        # Arrange arguments
        my $self = $class->SUPER::new(title => $title, author => $author);
        
        return $self;
    }

Instance initialization

    sub new {
        my $self = shift->SUPER::new(@_);
        
        # Initialization
        
        return $self;
    }

If you use one of "weak", "convert", or "trigger" options,
It will be better to initialize attributes.

    __PACKAGE__->attr(parent => (weak => 1));
    __PACAKGE__->attr(params => (convert => 'Parameters'));
    
    sub new {
        my $self = shift->SUPER::new(@_);
        
        foreach my $attr (qw/parent params/) {
            $self->$attr($self->{$attr}) if exists $self->{$attr};
        }
        
        return $self;
    }

This is a little bitter work. "init_attrs" of Object::Simple::Util is useful.
    
    use Object::Simple::Util;
    sub new {
        my $self = shift->SUPER::new(@_);
        
        Object::Simple::Util->init_attrs($self, qw/parent params/);
        
        return $self;
    }

=head2 attr

"attr" create accessor.
    
    __PACKAGE__->attr('name');
    __PACKAGE__->attr([qw/name1 name2 name3/]);

A default value can be specified.
If array ref, hash ref, or object is specified as a default value,
that must be wrapped with sub { }.

    __PACKAGE__->attr(name => 'foo');
    __PACKAGE__->attr(name => sub { ... });
    __PACKAGE__->attr([qw/name1 name2/] => 'foo');
    __PACKAGE__->attr([qw/name1 name2/] => sub { ... });

Various options can be specified.

    __PACKAGE__->attr(name => (default => sub {[]}, type => 'array', deref => 1));

=head2 class_attr

"class_attr" create accessor for class variable.

    __PACKAGE__->class_attr('name');
    __PACKAGE__->class_attr([qw/name1 name2 name3/]);
    __PACKAGE__->class_attr(name => 'foo');
    __PACKAGE__->class_attr(name => sub { ... });

This accessor is called from package, not instance.

    Book->title('BBB');

Class variables is saved to package variable "$CLASS_ATTRS". If you want to
delete the value or check existence, "delete", or "exists" function is available.

    delete $Book::CLASS_ATTRS->{title};
    exists $Book::CLASS_ATTRS->{title};

If this class is extended to subclass, the value is saved to subclass.
For example, Book->title('...') is saved to $Book::CLASS_ATTRS->{title},
and Magazine->title('...') is saved to $Magazine::CLASS_ATTRS->{title}

    package Book;
    use base 'Object::Simple::Base';
    
    __PACKAGE__->class_attr('title');
    
    package Magazine;
    use base 'Book';
    
    package main;
    
    Book->title('Beautiful days');
    Magazine->title('Good days');

=head2 hybrid_attr

"hybrid_attr" create accessor for instance variable and class variable.

    __PACKAGE__->hybrid_attr('name');
    __PACKAGE__->hybrid_attr([qw/name1 name2 name3/]);
    __PACKAGE__->hybrid_attr(name => 'foo');
    __PACKAGE__->hybrid_attr(name => sub { ... });

If this accessor is called from package, the value is saved to $CLASS_ATTRS.
If this accessor is called from instance, the value is saved to the instance.

    Book->title('Beautiful days');
    
    my $book = Book->new;
    $book->title('Good days');
    
=head1 Accessor options
 
=head2 default
 
Define a default value.

    __PACKAGE__->attr(title => (default => 'Good news'));

If a default value is array ref, or hash ref, or object,
the value is wrapped with sub { }.

    __PACKAGE__->attr(authors => (default => sub{ ['Ken', 'Taro'] }));
    __PACKAGE__->attr(ua      => (default => sub { LWP::UserAgent->new }));

Default value is also written in simple way.

    __PACKAGE__->attr(title   => 'Good news');
    __PACKAGE__->attr(authors => sub { ['Ken', 'Taro'] });
    __PACKAGE__->attr(ua      => sub { LWP::UserAgent->new });

=head2 weak

Weaken a reference.
 
    __PACKAGE__->attr(parent => (weak => 1));

=head2 type

Specify a variable type.

    __PACKAGE__->attr(authors => (type => 'array'));
    __PACKAGE__->attr(country_id => (type => 'hash'));

If list is passed to the accessor which type is "array",
the list is converted to a array ref automatically.

     $book->authors('ken', 'taro'); # ('ken', 'taro') -> ['ken', 'taro']
     $book->authors('ken');         # ('ken')         -> ['ken']

If list is passed to the accessor which type is "hash",
the list is converted to a hash ref automatically.

     $book->country_id(Japan => 1); # (Japan => 1)    -> {Japan => 1}

=head2 deref

Dereference a array ref or hash ref. "type" optios must be specified with "deref".
    
    __PACKAGE__->attr(authors    => (type => 'array', deref => 1));
    __PACKAGE__->attr(country_id => (type => 'hash',  deref => 1));

    my @authors = $book->authors;
    my %country_id = $book->country_id;

=head2 convert

Convert no blessed scalar value to a instance.

    __PACKAGE__->attr(url => (convert => 'URI'));
    $book->url('http://somehost'); # convert to a instance of URI.

Any subroutine is available to convert the value.

    __PACKAGE__->attr(url => (convert => sub{
        my $value = shift;
        $value = URI->new($value) unless ref $value;
        return $value;
    }));
    
=head2 trigger

Define a subroutine, which is called when the value is set.
This function is received the instance as first argument, 
and old value as second argument.

    __PACKAGE__->attr(error => (trigger => sub{
        my ($self, $old) = @_;
        $self->state('error') if $self->error;
    }));

=head2 clone

Package variable of super class is copied, If the accessor is for class.
Package variable is copied, If the accessor for instance.

"clone" is available by "class_attr", and "hybrid_attr".
This options is generally used with "default" value.

    __PACKAGE__->hybrid_attr(contraints => (clone => 'hash', default => sub { {} }));
    
"scalar", "array", "hash" is specified as "clone" options.

Any subroutine for clone is also available.

    __PACKAGE__->hybrid_attr(url => (default => sub { URI->new }, 
                                     clone   => sub { shift->clone }));

The explanation of "clone" is a little difficult. See "Prototype system"

=head1 Prototype system

L<Object::Simple::Base> provide a prototype system like JavaScript.

    +--------+ 
    | Class1 |
    +--------+ 
        |
        v
    +--------+    +----------+
    | Class2 | -> |instance2 |
    +--------+    +----------+

"Class1" has "title" accessor using "hybrid_attr" with "clone" options.

    package Class1;
    use base 'Object::Simple::Base';
    
    __PACKAGE__->hybrid_attr(title => (default => 'Good day', clone => 'scalar'));

"title" can be changed in "Class2".

    package Class2;
    use base Class1;
    
    __PACKAGE__->title('Beautiful day');
    
This value is used when instance is created. "title" value is "Beautiful day"

    package main;
    my $book = Class2->new;
    $book->title;

This prototype system is used in L<Validator::Custom> and L<DBIx::Custom>.

=head1 Export

Can import 'new' method to your package.

    package YourClass;
    use Object::Simple::Base 'new';

=head1 Similar module

This module is compatible with L<Mojo::Base>.

If you like L<Mojo::Base>, L<Object:Simple::Base> is good select for you.

=head1 Author
 
Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>
 
Github L<http://github.com/yuki-kimoto/>

I develope this module at L<http://github.com/yuki-kimoto/Object-Simple>

Please tell me bug if you find.

=head1 Copyright & license
 
Copyright 2008 Yuki Kimoto, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
 
1;

