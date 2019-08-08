use v5.12;
use warnings;

sub datetime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @_
        ? gmtime(shift) : gmtime;

    $wday = qw(Sun Mon Tue Wed Thu Fri Sat)[$wday];
    $mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon];
    $mday = sprintf '%02d',  $mday;
    $year += 1900;
    $hour = sprintf '%02d',  $hour;
    $min = sprintf '%02d',  $min;
    $sec = sprintf '%02d',  $sec;

    "$wday, $mday $mon $year $hour:$min:$sec GMT";
}

my @posts = sort { $b cmp $a || (stat $b)[9] <=> (stat $a)[9] } glob '2019-*.txt';

my $items = join "\n", map {
    my $name = $_;
    $name =~ s/\.txt$//;

    my $pub_date = datetime((stat $_)[9]);

    open my $fh, '<', $_;

    my $title;
    while (<$fh>) {
        chomp;
        if (/^\.title\s+(.+)/) {
            $title = $1;
            last;
        }
    }

    close $fh;

    <<EOI;
  <item>
   <title>$title</title>
   <link>https://cygx.github.io/$name</link>
   <guid isPermaLink="false">x-cygx:$name</guid>
   <pubDate>$pub_date</pubDate>
  </item>
EOI
} @posts;

my $build_date = datetime;

print <<EOF;
<?xml version="1.0"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
 <channel>

  <title>cygx's musings</title>
  <link>https://cygx.github.io/</link>
  <atom:link href="https://cygx.github.io/feed.rss" rel="self" type="application/rss+xml" />
  <description>life, the universe and programming woes</description>
  <lastBuildDate>$build_date</lastBuildDate>

$items
 </channel>
</rss>
EOF
