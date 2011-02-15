use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Brocco',
    AUTHOR              => q{Marco Fontani <MFONTANI@cpan.org>},
    VERSION_FROM        => 'lib/Brocco.pm',
    ABSTRACT            => 'Brocco - A Dancer blog engine',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                   => 0,
        'YAML'                         => 0,
        'Dancer'                       => 1.3003,
        'DBIx::Class'                  => 0,
        'Text::MultiMarkdown'          => 0,
        'Dancer::Plugin::DBIC'         => 0,
        'Dancer::Plugin::FlashMessage' => 0,
        'Dancer::Session::Cookie'      => 0,
        'Text::Xslate'                 => 0,
        'Dancer::Template::Xslate'     => 0,
        'Cache::Memcached::Fast'       => 0,
        'Date::Calc'                   => 0,
        'Digest::SHA'                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Brocco-*' },
);
