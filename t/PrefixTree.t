# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PrefixTree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Cwd;

use Test::More;

# é possível usar o módulo
BEGIN { use_ok('PrefixTree') };
# verificar se os métodos principais estão definidos
can_ok('PrefixTree', qw(new save load add_dict add_word rem_word get_words_with_prefix prefix_exists word_exists));

#########################

subtest 'Create PrefixTree' => sub {
  isa_ok( PrefixTree->new, 'PrefixTree' );
  isa_ok( PrefixTree->new('t/words_small'), 'PrefixTree' );
  isa_ok( PrefixTree->new('t/words_small.gz'), 'PrefixTree' );
  isa_ok( PrefixTree->new('t/words_small.bz2'), 'PrefixTree' );
  isa_ok( PrefixTree->new(qw(t/words_small t/words_small.gz t/words_small.bz2)), 'PrefixTree' );
};

sub check_words {
  my ($t, $test_words, $test_no_words) = @_;

  # verificar que existem no dicionario
  foreach my $w (@$test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }

  # verificar que palavras que não foram adicionadas não existem no dicionario
  foreach my $w (@$test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }
}

subtest 'Add and remove words' => sub {
  # criar uma prefix tree vazia e adicionar uma série de palavras
  my $t = PrefixTree->new;
  my @test_words = qw/a abacate abrenuncio abeto/;
  my @test_no_words = qw/abc abz afz as/;
  $t->add_word($_) for qw/a abacate abrenuncio abeto/;

  # remover uma palavra que não existia e verificar que continua tudo igual
  $t->rem_word('aba');
  check_words($t, [qw/a abacate abrenuncio abeto/], [qw/abc abz afz as/]);

  # remover um prefixo e verificar que funciona correctamente
  $t->rem_word('a');
  check_words($t, [qw/abacate abrenuncio abeto/], [qw/a abc abz afz as/]);

  # remover uma palavra cm um prefixo que também é uma palavra
  $t->add_word('a');
  $t->rem_word('abeto');
  check_words($t, [qw/a abacate abrenuncio/], [qw/abc abz afz as abeto/]);
};

subtest 'Save and load' => sub {
  # criar uma prefix tree vazia e adicionar uma série de palavras
  my $t = PrefixTree->new;
  my @test_words = qw/a abacate abrenuncio abeto/;
  my @test_no_words = qw/abc abz afz as/;
  $t->add_word($_) for @test_words;

  check_words($t, \@test_words, \@test_no_words);

  # save
  $t->save('t/test.save');

  # criar uma nova árvore
  $t = PrefixTree->new;

  check_words($t, [], [@test_words, @test_no_words]);

  # load
  $t->load('t/test.save');

  check_words($t, \@test_words, \@test_no_words);

  unlink 't/test.save'
};

sub check_words_with_prefix {
  my ($t, $prefix, $expected) = @_;
  my @got = sort $t->get_words_with_prefix($prefix);
  is_deeply( \@got, $expected, join(", ",@$expected).' são as unicas palavras com o prefixo '.$prefix );
}

subtest 'Prefix search' => sub {
  my $t = PrefixTree->new;

  # adicionar uma lista de palavras
  for my $w (qw/abespinhada abespinhado abespinhados abcesso abcessos mare marinheiro oliva/){
    $t->add_word($w);
  }

  ###############################
  ### check_words_with_prefix

  # testar com prefixos que existem
  check_words_with_prefix($t, 'abes', [qw/abespinhada abespinhado abespinhados/]);
  check_words_with_prefix($t, 'abc', [qw/abcesso abcessos/]);

  # testar com um prefixo que não existe
  check_words_with_prefix($t, 'abcdefg', []);

  ###############################
  ### prefix_exists

  # testar com um prefixo que existe
  foreach my $p (qw/ab oliva/) {
    ok($t->prefix_exists($p), "prefixo '$p' existe");
  }
  foreach my $p (qw/abespinhadas az me/) {
    ok(!$t->prefix_exists($p), "prefixo '$p' não existe");
  }

  # testar uma palavra que não existe e verificar se o prefixo passou a existir
  $t->word_exists('palavra');
  ok(!$t->prefix_exists('pa'), "prefixo 'pa' não existe");
};

done_testing();
