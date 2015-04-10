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

subtest 'Add and remove words' => sub {
  # criar uma prefix tree vazia e adicionar uma série de palavras
  my $t = PrefixTree->new;
  my @test_words = qw/a abacate abrenuncio abeto/;
  my @test_no_words = qw/abc abz afz as/;
  $t->add_word($_) for @test_words;

  # verificar que existem no dicionario
  foreach my $w (@test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }

  # verificar que palavras que não foram adicionadas não existem no dicionario
  foreach my $w (@test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }

  # remover uma palavra que não existia e verificar que continua tudo igual
  $t->rem_word('ola');
  foreach my $w (@test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }
  foreach my $w (@test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }

  # remover uma palavra que existia e verificar que deixou de existir
  $t->rem_word($test_words[0]);
  unshift( @test_no_words, shift(@test_words));
  foreach my $w (@test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }
  foreach my $w (@test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }
};

subtest 'Save and load' => sub {
  # criar uma prefix tree vazia e adicionar uma série de palavras
  my $t = PrefixTree->new;
  my @test_words = qw/a abacate abrenuncio abeto/;
  my @test_no_words = qw/abc abz afz as/;
  $t->add_word($_) for @test_words;

  # verificar que existem no dicionario
  foreach my $w (@test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }

  # verificar que palavras que não foram adicionadas não existem no dicionario
  foreach my $w (@test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }

  # save
  $t->save('t/test.save');

  # criar uma nova árvore
  $t = PrefixTree->new;

  # verificar que palavras que não foram adicionadas não existem no dicionario
  foreach my $w ( @test_words, @test_no_words ) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }

  # load
  $t->load('t/test.save');

  # verificar que existem no dicionario
  foreach my $w (@test_words) {
    ok($t->word_exists($w), "palavra '$w' existe");
  }

  # verificar que palavras que não foram adicionadas não existem no dicionario
  foreach my $w (@test_no_words) {
    ok(!$t->word_exists($w), "palavra '$w' não existe");
  }

  unlink 't/test.save'
};

subtest 'Prefix search' => sub {
  my $t = PrefixTree->new('t/words');
  my ($prefix,@expected,@got);

  # get_words_with_prefix
  $prefix = 'abes';
  @expected = qw/abespinhada abespinhado abespinhados/;
  @got = $t->get_words_with_prefix($prefix);
  is_deeply( \@got, \@expected, join(", ",@expected).' são as unicas palavras com o prefixo '.$prefix );

  $prefix = 'abc';
  @expected = qw/abcesso abcessos/;
  @got = $t->get_words_with_prefix($prefix);
  is_deeply( \@got, \@expected, join(", ",@expected).' são as unicas palavras com o prefixo '.$prefix );

  $prefix = 'abcdefg';
  @expected = qw//;
  @got = $t->get_words_with_prefix($prefix);
  is_deeply( \@got, \@expected, 'não existem palavras com o prefixo '.$prefix );


  # prefix_exists
  foreach my $p (qw/ab dua crep estra oliva mar/) {
    ok($t->prefix_exists($p), "prefixo '$p' existe");
  }
  foreach my $p (qw/aw wb zc/) {
    ok(!$t->prefix_exists($p), "prefixo '$p' não existe");
  }
};

done_testing();
