set PI 3.1415926535

proc lerp {a b v} {
	return [expr {$a * (1 - $v) + $b * $v}]
}

proc smooth {v} {
	return [expr {$v * $v * (3 - 2 * $v)}]
}

proc random_gradient {} {
	global PI
	set v [expr {rand() * $PI * 2}]
	return [list [expr {cos($v)}] [expr {sin($v)}]]
}

proc gradient {orig grad p} {
	set sp [list [expr {[lindex $p 0] - [lindex $orig 0]}]\
		     [expr {[lindex $p 1] - [lindex $orig 1]}]]
	return [expr {[lindex $grad 0] * [lindex $sp 0] +\
		      [lindex $grad 1] * [lindex $sp 1]}]
}

proc n2d_new {seed} {
	expr {srand($seed)}

	set permutations [lrepeat 256 0]
	set rgradients [lrepeat 256 0]

	for {set i 0} {$i < 256} {incr i} {
		lset rgradients $i [random_gradient]
	}

	for {set i 0} {$i < 256} {incr i} {
		set j [expr {round(rand() * 65536) % ($i + 1)}]
		lset permutations $i [lindex $permutations $j]
		lset permutations $j $i
	}

	set n2d(permutations) $permutations
	set n2d(rgradients) $rgradients
	return [array get n2d]
}

proc n2d_get_gradient {ctx x y} {
	upvar $ctx n2d
	set idx [expr {[lindex $n2d(permutations) [expr {$x & 255}]] +\
	               [lindex $n2d(permutations) [expr {$y & 255}]]}]
	return [lindex $n2d(rgradients) [expr {$idx & 255}]]
}

proc n2d_get_gradients {ctx x y} {
	upvar $ctx n2d
	set x0f [expr {floor($x)}]
	set y0f [expr {floor($y)}]
	set x0 [expr {round($x0f)}]
	set y0 [expr {round($y0f)}]
	set x1 [expr {$x0 + 1}]
	set y1 [expr {$y0 + 1}]

	set n2d(gradients) [list [n2d_get_gradient n2d $x0 $y0]\
	                         [n2d_get_gradient n2d $x1 $y0]\
	                         [n2d_get_gradient n2d $x0 $y1]\
	                         [n2d_get_gradient n2d $x1 $y1]]

	set n2d(origins) [list [list [expr {$x0f + 0}] [expr {$y0f + 0}]]\
	                       [list [expr {$x0f + 1}] [expr {$y0f + 0}]]\
	                       [list [expr {$x0f + 0}] [expr {$y0f + 1}]]\
	                       [list [expr {$x0f + 1}] [expr {$y0f + 1}]]]
}

proc n2d_get {ctx x y} {
	upvar $ctx n2d
	set p [list $x $y]
	n2d_get_gradients n2d $x $y
	set v0 [gradient [lindex $n2d(origins) 0] [lindex $n2d(gradients) 0] $p]
	set v1 [gradient [lindex $n2d(origins) 1] [lindex $n2d(gradients) 1] $p]
	set v2 [gradient [lindex $n2d(origins) 2] [lindex $n2d(gradients) 2] $p]
	set v3 [gradient [lindex $n2d(origins) 3] [lindex $n2d(gradients) 3] $p]
	set fx [smooth [expr {$x - [lindex [lindex $n2d(origins) 0] 0]}]]
	set vx0 [lerp $v0 $v1 $fx]
	set vx1 [lerp $v2 $v3 $fx]
	set fy [smooth [expr {$y - [lindex [lindex $n2d(origins) 0] 1]}]]
	return [lerp $vx0 $vx1 $fy]
}

proc main {} {
	set symbols {{ } {░} {▒} {▓} {█} {█}}
	set pixels [lrepeat [expr 256*256] 0]
	array set n2d [n2d_new 0]

	for {set i 0} {$i < 100} {incr i} {
		for {set y 0} {$y < 256} {incr y} {
			for {set x 0} {$x < 256} {incr x} {
				set v [n2d_get n2d [expr {$x * 0.1}] [expr {$y * 0.1}]]
				set v [expr {$v * 0.5 + 0.5}]
				lset pixels [expr {$y*256+$x}] $v
			}
		}
	}

	for {set y 0} {$y < 256} {incr y} {
		for {set x 0} {$x < 256} {incr x} {
			set p [lindex $pixels [expr {$y*256+$x}]]
			puts -nonewline [lindex $symbols [expr {round($p / 0.2)}]]
		}
		puts {}
	}
}

main
