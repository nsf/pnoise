#!/usr/bin/perl6

class Vec2 {
	has $.x;
	has $.y;
}

sub lerp($a, $b, $v) {
	$a * (1 - $v) + $b * $v
}

sub smooth($v) {
	$v * $v * (3 - 2 * $v)
}

sub random_gradient {
	my $v = rand * pi * 2;
	Vec2.new(x => cos($v), y => sin($v))
}

sub gradient($orig, $grad, $p) {
	my $sp = Vec2.new(x => $p.x - $orig.x, y => $p.y - $orig.y);
	$grad.x * $sp.x + $grad.y * $sp.y
}

class Noise2DContext {
	has @.rgradients;
	has @.permutations;
	has @.gradients;
	has @.origins;

	method new($seed) {
		srand($seed);

		my @rgradients;
		for 0..255 {
			@rgradients.push(random_gradient);
		}

		my @permutations;
		for 0..255 -> $i {
			@permutations.push($i);
		}
		@permutations = @permutations.pick(*);

		self.bless(:@permutations, :@rgradients,
			gradients => [Any, Any, Any, Any],
			origins => [Any, Any, Any, Any]);
	}

	method get_gradient($x, $y) {
		my $idx = @!permutations[$x +& 255] + @!permutations[$y +& 255];
		@!rgradients[$idx +& 255]
	}

	method get_gradients($x, $y) {
		my $x0f = floor $x;
		my $y0f = floor $y;
		my $x0 = $x0f.Int;
		my $y0 = $y0f.Int;
		my $x1 = $x0 + 1;
		my $y1 = $y0 + 1;

		@!gradients[0] = self.get_gradient($x0, $y0);
		@!gradients[1] = self.get_gradient($x1, $y0);
		@!gradients[2] = self.get_gradient($x0, $y1);
		@!gradients[3] = self.get_gradient($x1, $y1);

		@!origins[0] = Vec2.new(x => $x0f + 0.0, y => $y0f + 0.0);
		@!origins[1] = Vec2.new(x => $x0f + 1.0, y => $y0f + 0.0);
		@!origins[2] = Vec2.new(x => $x0f + 0.0, y => $y0f + 1.0);
		@!origins[3] = Vec2.new(x => $x0f + 1.0, y => $y0f + 1.0);
	}

	method get($x, $y) {
		my $p = Vec2.new(:$x, :$y);
		self.get_gradients($x, $y);
		my $v0 = gradient(@!origins[0], @!gradients[0], $p);
		my $v1 = gradient(@!origins[1], @!gradients[1], $p);
		my $v2 = gradient(@!origins[2], @!gradients[2], $p);
		my $v3 = gradient(@!origins[3], @!gradients[3], $p);

		my $fx = smooth($x - @!origins[0].x);
		my $vx0 = lerp($v0, $v1, $fx);
		my $vx1 = lerp($v2, $v3, $fx);
		my $fy = smooth($y - @!origins[0].y);
		lerp($vx0, $vx1, $fy)
	}
}

my @symbols = [' ', '░', '▒', '▓', '█', '█'];
my @pixels = map {0}, (0..65535);
my $n2d = Noise2DContext.new(0);
	for 0..255 -> $y {
		for 0..255 -> $x {
			my $v = $n2d.get($x * 0.1, $y * 0.1) * 0.5 + 0.5;
			@pixels[$y*256+$x] = @symbols[$v / 0.2]
		}
	}

for 0..255 -> $y {
	for 0..255 -> $x {
		print @pixels[$y*256+$x]
	}
	print "\n"
}
