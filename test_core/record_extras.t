#!/usr/bin/perl

use Test;
BEGIN { plan tests => 16 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

my $record_class = $sqldb->record_class('foo', 'My::Foo', 'Extras');
ok( $record_class eq 'My::Foo' );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Base') );
ok( My::Foo->isa('DBIx::SQLEngine::Record::Extras') );
ok( eval { My::Foo->demand_table } );
ok( ref My::Foo->can('fetch_records') );
ok( ref My::Foo->can('refetch_record') );

########################################################################

# The record interface requires information about the columns, which isn't 
# available in our bogus NullP environment, so we'll define them explicitly.

My::Foo->columnset( 
  DBIx::SQLEngine::Schema::ColumnSet->new(  
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'bar' ),
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'buz' ),
  ) 
);

########################################################################

My::Foo->fetch_select( );
ok( $sqldb->last_query, 'select * from foo' );

My::Foo->fetch_select( criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ?/Baz' );

My::Foo->select_record( 'Baz' );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

My::Foo->select_record( { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

My::Foo->new_and_save( buz => 'Baz' );
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (NULL, ?)/Baz' );

My::Foo->new_with_values( bar => 'Baz', buz => 'Blee' )->insert_record;
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (?, ?)/Baz/Blee' );

My::Foo->new_with_values( bar => 'Baz', buz => 'Blee' )->update_record;
ok( $sqldb->last_query, 'update foo set bar = ?, buz = ? where bar = ?/Baz/Blee/Baz' );

My::Foo->new_with_values( bar => 'Baz' )->delete_record();
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );

########################################################################

1;
