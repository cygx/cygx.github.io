use strict;
use warnings;

my $rx_attribute = '(?:\\[\\w+(?: [^\\]]*)?\\])';
my $rx_tag = '(?:<\\/?\w[^>]*(?<!\\s)>)';

my %tags = (
    '`' => 'code',
    '-' => 'em',
    '*' => 'strong',
);

my @out;
my $sections = 0;

sub echo {
    push @out, @_;
}

sub slurp {
    local $/;
    local $_ = <>;
    chomp;
    $_;
}

sub preprocess {
    local $_ = shift;

    while (/(%([I])%)/) {
        my $outer = $1;
        my $macro = $2;
        # TODO
        s{\Q$outer\E}{$sections};
    }

    $_;
}

sub postprocess {
    local $_ = shift;

    while (/(%([N])%)/) {
        my $outer = $1;
        my $macro = $2;
        # TODO
        s{\Q$outer\E}{$sections};
    }

    $_;
}

sub parse_formatting {
    local $_ = shift;

    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;

    while (/(?:^|\s)\K(([-*`])(\S.*?(?<=\S))\g{-2})(?=\W|$)/) {
        my $outer = $1;
        my $tag = $tags{$2};
        my $inner = $3;
        s{\Q$outer\E}{<$tag>$inner</$tag>};
    }

    $_;
}

sub parse_attributes {
    local $_ = shift;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/"/&quot;/;

    my $attrs = '';
    while (s/\[(\w+)(?: ([^\]]*))?\]//) {
        $attrs .= " $1";
        $attrs .= "=\"$2\"" if $2;
    }

    $attrs;
}

sub parse_math {
    my @tokens = split /(?:^|\s)\K(\$.*?\$(?:\W|$))/;

    for (@tokens) {
        next if s/^\$(.*)\$(\W?)$/\\\($1\\\)$2/;
        $_ = parse_formatting $_;
    }

    join '', @tokens;
}

sub parse_markup {
    my @tokens = split /([!@]\[[^\]]*\]\[[^\]]+\]$rx_attribute*)/, shift;

    for (@tokens) {
        if (/([!@])\[([^\]]*)\]\[([^\]]+)\]($rx_attribute*)/) {
            my ($type, $text, $address, $attrs) = ($1, $2, $3, $4);
            $attrs = parse_attributes $attrs if $attrs;
            $text = $address unless $text;
            $_ = $type eq '!' ? "<img src=\"$address\" alt=\"$text\"$attrs>" :
                 $type eq '@' ? "<a href=\"$address\"$attrs>$text</a>" :
                 die;

            next;
        }

        $_ = parse_math $_;
    }

    join '', @tokens;
}

sub parse_html {
    my @tokens = split /($rx_tag)/, shift;

    for (@tokens) {
        next if /$rx_tag/;
        $_ = parse_markup $_;
    }

    join '', @tokens;
}

sub parse_line {
    local $_ = shift;
    return $_ if s/^    //;

    my ($wrapper, $attrs);
    if (s/^\.(\w+)($rx_attribute*)(?:\s|$)//) {
        $wrapper = $1;
        $attrs = $2 ? parse_attributes($2) : '';
    }

    $_ = parse_html $_;
    $wrapper ? "<$wrapper$attrs>$_</$wrapper>" : $_;
}

sub parse {
    join "\n", map { parse_line $_ } split /\n/, shift;
}

sub spurt_block {
    local $_ = shift;

    # section
    if (/^---$/) {
        echo "</div>" if $sections;
        ++$sections;
        echo "<div class=\"section\" id=\"s-$sections\">\n\n";
    }

    # code block
    elsif (/^``\n(.*)\n``$/s) {
        my $tag = $tags{'`'};
        echo "<pre><$tag>".parse($1)."</$tag></pre>\n\n"
    }

    # math block
    elsif (/^\$\$\n(.*)\n\$\$$/s) {
        echo "<div>\\[".parse($1)."\\]</div>\n\n";
    }

    # heading
    elsif (s/^(#+)\s+//) {
        my $tag = 'h'.length($1);
        echo "<$tag>".parse($_)."</$tag>\n\n";
    }

    # element
    elsif (s/^\:(\w+)($rx_attribute*)(?:\n|$)//) {
        my $tag = $1;
        my $attrs = $2 ? parse_attributes($2) : '';
        if ($tag eq 'ul') { s/^\s+-(?=\s)/.li/mg }
        elsif ($tag eq 'ol') { s/^\s+(\d+)\.(?=\s)/.li[value $1]/mg }
        echo "<$tag$attrs>".parse($_)."</$tag>\n\n";
    }

    # html tag
    elsif (/^(<(\w+)[^>]*(?<!\s)>)\n(.*)\n<\/\g2>$/s) {
        echo "$1".parse($3)."</$2>\n\n";
    }

    # paragraph
    else {
        echo "<p>".parse($_)."</p>\n\n";
    }
}

sub spurt {
    echo "<!DOCTYPE html>\n";
    spurt_block preprocess($_) for split /\n{2,}/, shift;
    echo "</div>\n" if $sections;

    print postprocess($_) for @out;
}

spurt slurp;
