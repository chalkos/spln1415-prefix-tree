package PrefixTree;

use 5.020001;
use strict;
use warnings;

use Data::Dumper;
use Storable;

#require Exporter;

#our @ISA = qw(Exporter);

# exportar várias coisas de uma vez agrupadas
#our %EXPORT_TAGS = ( 'all' => [ qw() ] );

# o que se pode importar individualmente
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# o que é importado por omissão
#our @EXPORT = qw();

our $VERSION = '0.01';

# object methods

sub new{
  my $class = shift;
  my $self = bless {'tree'=>{}}, $class;
  for my $file (@_) {
    $self->add_dict($file);
  }
  return $self;
}

sub save{
  my ($self,$filename) = @_;
  store($self->{'tree'}, $filename) or die "cannot save tree to '$filename': $!";
}

sub load{
  my ($self,$filename) = @_;
  $self->{'tree'} = retrieve($filename) or die "cannot load tree from '$filename': $!";
}

sub add_dict{
  my ($self, $dict) = @_;
  my $in;
  if($dict =~ /gz$/){
    open($in, "zcat $dict |") or die "cannot open '$dict': $!";
  }elsif($dict =~ /bz2$/){
    open($in, "bzcat $dict |") or die "cannot open '$dict': $!";
  }else{
    open($in, "<", $dict) or die "cannot open '$dict': $!";
  }

  $self->add_word($_) while(<$in>);

  close($in);
}

sub add_word{
  my ($self,$pal) = @_;
  eval '$self->{"tree"}' . (join '', map { "{'$_'}" } _palToChars($pal)) . "{'end'}=1"
}

sub rem_word{
  my ($self,$pal) = @_;
  my $hash = $self->{'tree'};

  my @chars = _palToChars($pal);

  _remove_pal_rec($hash,\@chars);
}

sub get_words_with_prefix{
  my ($self,$pal) = @_;
  my $hash = $self->{'tree'};

  my @chars = _palToChars($pal);

  foreach my $x (@chars) {
    return () unless exists $hash->{$x};
    $hash = $hash->{$x};
  }

  my @result = ();

  _get_down_word($hash,$pal,\@result);

  return @result;
}

sub prefix_exists{
  my ($self,$pal) = @_;
  my $hash = $self->{'tree'};

  my @chars = _palToChars($pal);

  foreach my $x (@chars) {
    return 0 unless exists $hash->{$x};
    $hash = $hash->{$x};
  }
  return 1;
}

sub word_exists{
  my ($self,$pal) = @_;
  my $hash = $self->{'tree'};

  my @chars = _palToChars($pal);

  foreach my $x (@chars) {
    return 0 unless exists $hash->{$x};
    $hash = $hash->{$x};
  }
  return exists $hash->{'end'};
}

# PRIVATE METHODS

sub _palToChars {
  my $pal = shift;
  chomp $pal;
  $pal = lc $pal;
  my @chars = split('',$pal);
}

sub _get_down_word {
  my ($hash,$pal,$res) = @_;

  foreach my $x (keys %$hash) {
    if ($x eq 'end') {
      push(@$res,$pal);
    } else {
      _get_down_word($hash->{$x}, $pal.$x, $res);
    }
  }
}

sub _remove_pal_rec {
  my ($hash,$chars) = @_;

  if (!@$chars){
    # Se existir um end remove-o
    if (exists $hash->{'end'}) {
      delete $hash->{'end'};
    }
  } else {
    my $letter = shift @$chars;

    if (exists $hash->{$letter}) {
      _remove_pal_rec($hash->{$letter}, $chars);
      # Remover Hash se estiver vazia
      unless (%{$hash->{$letter}}) {
        delete $hash->{$letter};
      }
    }
  }
}


1;
__END__

=encoding utf8

=head1 NAME

PrefixTree - Árvore de prefixos em perl

=head1 CONTEXT

Primeiro Trabalho Prático de SPLN, Mestrado em Engenharia Informática @ Universidade do Minho

=head1 SYNOPSIS

  use Data::Dumper;
  use PrefixTree;

  # Cria um objecto e inicializa-o com dois ficheiros sendo o primeiro
  # em texto e o segundo compactado com o comando bzip2
  my $pt = new PrefixTree(qw {smalldict.txt dic.bz2});

  # Adiciona algumas palavras
  $pt->add_word($_) for (qw {aba abaco abeto abrir aberto abertura});

  print Dumper($pt);

  # Imprime todas as palavras que tenham os prefixos ab e ap
  printf("%s: %s\n", $_, join(" ", $pt->get_words_with_prefix($_))) for (qw {ab ap});

=head1 DESCRIPTION

Uma árvore de prefixos armazena todos os prefixos das palavras introduzidas. Uma das grandes vantagens desta estrutura é que serve para armazenar uma lista de palavras de uma forma compacta.

=head1 EXPORT

=head2 new

O construtor que poderá receber vários argumentos, sendo cada argumento o nome de um ficheiro. Caso estes ficheiros tenham a extensão .gz ou .bz2 então o ficheiro está compactado e deverá ser aberto usando os comandos gunzip ou bunzip2 respetivamente

=head2 save

Este método permite armazenar (existe um módulo chamado Storable1) o objeto em disco

=head2 load

Este método permite consultar o objeto guardado previamente com o método save

=head2 add_dict

Este método permite adicionar mais ficheiros (deve-se usar mais uma vez a estratégia acima)

=head2 add_word

Este método permite adicionar mais uma palavra

=head2 rem_word

Este método permite remover uma palavra

=head2 get_words_with_prefix

Este método devolve uma lista de todas as palavras que contenham um dado prefixo

=head2 prefix_exists

Este método devolve verdadeiro ou falso caso o prefixo exista no dicionário

=head2 word_exists

Este método devolve verdadeiro ou falso caso a palavra exista no dicionário

=head1 SEE ALSO

Enunciado do exercício: https://github.com/rcm/spln1415/tree/master/aula05

Repositório de código: https://github.com/chalkos/spln1415-prefix-tree

=head1 AUTHORS

Bruno Ferreira, https://github.com/chalkos

Miguel Pinto, https://github.com/miguelpinto98

=cut
