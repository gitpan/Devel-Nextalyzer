use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Devel::Nextalyzer',
    'VERSION_FROM' => 'Nextalyzer.pm',
    'PREREQ_PM'    => {
        NEXT              => '0.60',
        Class::ISA        => 0,
        Text::SimpleTable => 0
    },
);
