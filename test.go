package main

import (
	"bufio"
	"fmt"
	"math"
	"math/rand"
	"os"
)

type Vec2 struct{ X, Y float32 }

func lerp(a, b, v float32) float32 { return a*(1-v) + b*v }
func smooth(v float32) float32     { return v * v * (3 - 2*v) }

func gradient(orig, grad, p Vec2) float32 {
	sp := Vec2{p.X - orig.X, p.Y - orig.Y}
	return grad.X*sp.X + grad.Y*sp.Y
}

type Noise2DContext struct {
	rgradients   [256]Vec2
	permutations [256]int
	gradients    [4]Vec2
	origins      [4]Vec2
}

func NewNoise2DContext(seed int) *Noise2DContext {
	rnd := &pcg{uint64(seed), 0}
	n2d := new(Noise2DContext)
	copy(n2d.permutations[:], rand.Perm(256))
	for i := range n2d.rgradients {
		x, y := rnd.Box32(), rnd.Box32()
		inv := InvSqrt(x*x + y*y)
		n2d.rgradients[i] = Vec2{x * inv, y * inv}
	}
	return n2d
}

func (n2d *Noise2DContext) gradientAt(x, y int) Vec2 {
	idx := n2d.permutations[x&255] + n2d.permutations[y&255]
	return n2d.rgradients[idx&255]
}

func (n2d *Noise2DContext) updateGradients(x, y float32) {
	x0, y0 := int(x), int(y)
	x1, y1 := x0+1, y0+1

	n2d.gradients[0] = n2d.gradientAt(x0, y0)
	n2d.gradients[1] = n2d.gradientAt(x1, y0)
	n2d.gradients[2] = n2d.gradientAt(x0, y1)
	n2d.gradients[3] = n2d.gradientAt(x1, y1)

	x0f, y0f := float32(x0), float32(y0)
	x1f, y1f := x0f+1.0, y0f+1.0
	n2d.origins[0] = Vec2{x0f, y0f}
	n2d.origins[1] = Vec2{x1f, y0f}
	n2d.origins[2] = Vec2{x0f, y1f}
	n2d.origins[3] = Vec2{x1f, y1f}
}

func (n2d *Noise2DContext) Get(x, y float32) float32 {
	p := Vec2{x, y}
	n2d.updateGradients(x, y)
	v0 := gradient(n2d.origins[0], n2d.gradients[0], p)
	v1 := gradient(n2d.origins[1], n2d.gradients[1], p)
	v2 := gradient(n2d.origins[2], n2d.gradients[2], p)
	v3 := gradient(n2d.origins[3], n2d.gradients[3], p)
	fx := smooth(x - n2d.origins[0].X)
	vx0 := lerp(v0, v1, fx)
	vx1 := lerp(v2, v3, fx)
	fy := smooth(y - n2d.origins[0].Y)
	return lerp(vx0, vx1, fy)
}

func main() {
	symbols := []string{" ", "░", "▒", "▓", "█", "█"}
	pixels := make([]float32, 256*256)
	n2d := NewNoise2DContext(0)
	for i := 0; i < 100; i++ {
		for y := 0; y < 256; y++ {
			for x := 0; x < 256; x++ {
				v := n2d.Get(float32(x)*0.1, float32(y)*0.1)
				v = v*0.5 + 0.5
				pixels[y*256+x] = v
			}
		}
	}

	out := bufio.NewWriter(os.Stdout)
	for y := 0; y < 256; y++ {
		for x := 0; x < 256; x++ {
			fmt.Fprint(out, symbols[int(pixels[y*256+x]/0.2)])
		}
		fmt.Fprintln(out)
	}
	out.Flush()
}

// utils

// a faster random generator
type pcg struct {
	state uint64
	inc   uint64
}

func (pcg *pcg) Uint32() uint32 {
	old := pcg.state
	// Advance internal state
	pcg.state = old*6364136223846793005 + pcg.inc | 1
	// Calculate output function (XSH RR), uses old state for max ILP
	xor := uint32(((old >> 18) ^ old) >> 27)
	rot := uint32(old >> 59)
	return (xor >> rot) | (xor << ((-rot) & 31))
}

func (pcg *pcg) Float32() float32 {
	return float32(pcg.Uint32()) / float32(1<<32-1)
}

func (pcg *pcg) Box32() float32 {
	return float32(int32(pcg.Uint32())) / float32(1<<31-1)
}

func InvSqrt(x float32) float32 {
	xhalf := float32(0.5) * x
	i := math.Float32bits(x)
	i = 0x5f3760df - i>>1
	x = math.Float32frombits(i)
	x = x * (1.5 - (xhalf * x * x))
	return x
}
