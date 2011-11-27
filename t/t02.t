#===============================================================================
#
#  DESCRIPTION:  Test soy syntax
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
use strict;
use warnings;

use Test::More tests => 11;    # last test to print
use Data::Dumper;
use v5.10;
use Regexp::Grammars;
use Plosurin::Grammar;
use Plosurin::SoyTree;

my $q = qr{
     <extends: Plosurin::Grammar>
#    <debug:step>
    \A  <[content]>* \Z
}xms;

my @t;
my $STOP_TREE = 0;

# Looks like you failed 1 test of 1.
@t = ();

#@t = ('{call .test }{param test : 1 /}{/call}');

my @grammars = (
    "<h1>test</h2>", [
        {
            'Soy::raw_text' => {}
        }
    ], 'raw text',
    '{$acr}', [ {
            'Soy::command_print' => {}
        } ], undef,

    "{print 2}", [
        {
            'Soy::command_print' => {}
        }
    ], 'print',

    "{if 2} {/if}",
    [
        {
            'Soy::command_if' => {
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{/if}",

    '{if 2} raw text {elseif 34}  asdasd{else} none {/if}',
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{elseif}..{/if}",

    "{if 2} raw text {else} none {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    '{if}..{else}..{if}',

    "{if 2} raw text   
     {elseif 3}   1     
     {elseif 4}   3     
     {else} none  
     {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    },
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    '{if}..{elseif}..{elseif}..{else}..{if}',

    "{if 2} raw text
     {elseif 4}
         3 {print 4}   2{else}
         1
    {/if}",
    [
        {
            'Soy::command_if' => {
                'else' => {
                    'Soy::command_else' =>
                      { 'childs' => [ { 'Soy::raw_text' => {} } ] }
                },
                'elseif' => [
                    {
                        'Soy::command_elseif' => {
                            'expression' => {},
                            'childs'     => [
                                { 'Soy::raw_text'      => {} },
                                { 'Soy::command_print' => {} },
                                { 'Soy::raw_text'      => {} }
                            ]
                        }
                    }
                ],
                'if' => {
                    'expression' => {},
                    'childs'     => [ { 'Soy::raw_text' => {} } ]
                }
            }
        }
    ],
    "{if}..{elseif}..{print}..{else}..{/if}",

    #{call}
    '{call .test_template data="all"/}',
    [
        {
            'Soy::command_call_self' => {
                'attrs'    => { 'data' => 'all' },
                'template' => '.test_template'
            }
        }
    ],
    '{call../}',
    '{call .test }{param test : 1 /}{param data}text{/param}{/call}',
    [
        {
            'Soy::command_call' => {
                'attrs'    => {},
                'template' => '.test',
                'childs'   => [
                    {
                        'Soy::command_param_self' => {
                            'value' => '1',
                            'name'  => 'test'
                        }
                    },
                    {
                        'Soy::command_param' => {
                            'name'   => 'data',
                            'childs' => [ { 'Soy::raw_text' => {} } ]
                        }
                    }
                ]
            }
        }
    ],
    undef,

    '{call test.ok}{param t }<br/>{/param}{param d : 1 /}{/call}',
    [
        {
            'Soy::command_call' => {
                'attrs'    => {},
                'template' => 'test.ok',
                'childs'   => [
                    {
                        'Soy::command_param' => {
                            'name'   => 't',
                            'childs' => [ { 'Soy::raw_text' => {} } ]
                        }
                    },
                    {
                        'Soy::command_param_self' => {
                            'value' => '1',
                            'name'  => 'd'
                        }
                    }
                ]
            }
        }
    ],
    undef

);

@grammars = @t if scalar(@t);
while ( my ( $src, $extree, $name ) = splice( @grammars, 0, 3 ) ) {
    $name //= $src;
    my $plo = Plosurin::SoyTree->new( src => $src );
    unless ( ref($plo) ) { fail($name) }
    if ($STOP_TREE) { say Dumper( $plo->raw_tree ); exit; }
    my $tree     = $plo->reduced_tree();
    my $res_tree = $plo->dump_tree($tree);
    is_deeply( $res_tree, $extree, $name )
      || do { say "fail Deeeple" . Dumper( $res_tree, $extree, ); exit; };

}
