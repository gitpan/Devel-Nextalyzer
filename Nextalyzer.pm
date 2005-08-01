package Devel::Nextalyzer;

use strict;
use Class::ISA;
use Text::ASCIITable;
use Text::ASCIITable::Wrap qw/wrap/;

our $VERSION = '0.01';
our $RAW     = 0;

=head1 NAME

Devel::Nextalyzer - Making Multiple Inheritance and NEXT less scary

=head1 SYNOPSIS

    # Compile time
    use Devel::Nextalyzer;

    # Runtime
    require Devel::Nextalyzer;
    import Devel::Nextalyzer;

=head1 DESCRIPTION

Multiple Inheritance and L<NEXT> are great tools for the right tasks,
this ana this analyzer will make it much less scary.

It will analyze the calling class and make dump to C<STDERR> on C<import>.

You may set C<$Devel::Nextalyzer::RAW> to get raw output.

=cut

sub import {
    my $class = caller(0);
    my @path  = reverse Class::ISA::super_path($class);

    my %provided;
    my %overloaded;

    my @t;
    my $t = Text::ASCIITable->new;
    $t->setCols( 'Class', 'Provided Methods', 'Overloaded Methods' );
    $t->setColWidth( 'Class',              24, 1 );
    $t->setColWidth( 'Provided Methods',   23, 1 );
    $t->setColWidth( 'Overloaded Methods', 23, 1 );

    my @np;
    my $np = Text::ASCIITable->new;
    $np->setCols('Method');
    $np->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
    $np->setColWidth( 'Method', 74, 1 );

    my @mix;
    my $mix = Text::ASCIITable->new;
    $mix->setCols( 'Class', 'Method' );
    $mix->setColWidth( 'Class',  37, 1 );
    $mix->setColWidth( 'Method', 36, 1 );

    foreach my $super (@path) {
        my $file = $super;
        $file =~ s/\:\:/\//g;
        $file .= '.pm';
        my $file_path = $INC{$file};
        die "Couldn't get INC for $file, super $super" unless $file_path;

        open IN, '<', $file_path;
        my $in_sub;
        my $ws;
        my $uses_next;
        my @provides;
        my @overloads;
        while ( my $line = <IN> ) {
            unless ($in_sub) {
                ( $ws, $in_sub ) = ( $line =~ /^(\s*)sub (\S+)/ );
                next unless $in_sub;
            }
            if ( $line =~ /^$ws\}/ ) {
                if ($uses_next) {
                    push( @overloads, $in_sub );
                }
                else {
                    push( @provides, $in_sub );
                }
                undef $in_sub;
                undef $uses_next;
                undef $ws;
                next;
            }
            $uses_next++ if ( $line =~ /\-\>NEXT/ );
        }
        close IN;
        foreach (@overloads) {
            $np->addRow( wrap( $_, 47, 1 ) ) unless $provided{$_};
            push @np, "$_\n";
            push( @{ $overloaded{$_} }, $super );
        }
        $provided{$_} = $super for @provides;
        my $provides  = join( "\n", @provides );
        my $overloads = join( "\n", @overloads );
        $t->addRow(
            wrap( $super,     24, 1 ),
            wrap( $provides,  23, 1 ),
            wrap( $overloads, 23, 1 )
        );
        $provides  =~ s/\n/ /g;
        $overloads =~ s/\n/ /g;
        push @t, "$super, $provides, $overloads\n";
    }
    print STDERR qq/Devel::Nextalyzer analysis for class "$class":\n/;
    print STDERR $RAW ? join( '', @t ) : $t->draw;
    print STDERR "\n";

    print STDERR qq/Overloaded but not provided methods (probably harmless):\n/;
    print STDERR $RAW ? join( '', @np ) : $np->draw;
    print STDERR "\n";

    foreach my $o ( keys %overloaded ) {
        my $pr = $provided{$o};
        my $mixins = join( "\n", reverse @{ $overloaded{$o} } );
        $mix->addRow( wrap( $mixins, 37, 1 ), wrap( $o, 36, 1 ) ) unless $pr;
        $mixins =~ s/\n/ /g;
        push @mix, "$mixins, $o";
    }

    print STDERR
      qq/Methods not found in source code (mixins, probably harmless):\n/;
    print STDERR $RAW ? join( "\n", @mix ) : $mix->draw;
    print STDERR "\n\n";
}

=head1 SEE ALSO

L<NEXT>, L<DBIx::Class>, L<Catalyst>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>
Matt S Trout

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
