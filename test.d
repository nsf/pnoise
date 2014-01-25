import std.stdio;
import std.random;
import std.math;

struct Vec2 {
	float x, y;
}

float lerp(float a, float b, float v)
{
	return a * (1 - v) + b * v;
}

float smooth(float v)
{
	return v * v * (3 - 2 * v);
}

Vec2 random_gradient(Random)(ref Random r)
{
	auto v = uniform(0.0f, cast(float)PI * 2.0f, r);
	return Vec2(cos(v), sin(v));
}

float gradient(Vec2 orig, Vec2 grad, Vec2 p)
{
	auto sp = Vec2(p.x - orig.x, p.y - orig.y);
	return grad.x * sp.x + grad.y * sp.y;
}

class Noise2DContext {
	Vec2[256] rgradients;
	uint[256] permutations;
	Vec2[4] gradients;
	Vec2[4] origins;

private:
	Vec2 get_gradient(int x, int y)
	{
		auto idx = permutations[x & 255] + permutations[y & 255];
		return rgradients[idx & 255];
	}

	void get_gradients(float x, float y)
	{
		float x0f = floor(x);
		float y0f = floor(y);
		int x0 = cast(int)x0f;
		int y0 = cast(int)y0f;
		int x1 = x0 + 1;
		int y1 = y0 + 1;

		gradients[0] = get_gradient(x0, y0);
		gradients[1] = get_gradient(x1, y0);
		gradients[2] = get_gradient(x0, y1);
		gradients[3] = get_gradient(x1, y1);

		origins[0] = Vec2(x0f + 0.0f, y0f + 0.0f);
		origins[1] = Vec2(x0f + 1.0f, y0f + 0.0f);
		origins[2] = Vec2(x0f + 0.0f, y0f + 1.0f);
		origins[3] = Vec2(x0f + 1.0f, y0f + 1.0f);
	}

public:
	this(uint seed)
	{
		auto rnd = Random(seed);
		foreach (ref elem; rgradients)
			elem = random_gradient(rnd);

		foreach (i; 0 .. permutations.length) {
			uint j = uniform(0, cast(uint)i+1, rnd);
			permutations[i] = permutations[j];
			permutations[j] = cast(uint)i;
		}
	}

	float get(float x, float y)
	{
		auto p = Vec2(x, y);

		get_gradients(x, y);
		auto v0 = gradient(origins[0], gradients[0], p);
		auto v1 = gradient(origins[1], gradients[1], p);
		auto v2 = gradient(origins[2], gradients[2], p);
		auto v3 = gradient(origins[3], gradients[3], p);

		auto fx = smooth(x - origins[0].x);
		auto vx0 = lerp(v0, v1, fx);
		auto vx1 = lerp(v2, v3, fx);
		auto fy = smooth(y - origins[0].y);
		return lerp(vx0, vx1, fy);
	}
}


void main()
{
	immutable symbols = [" ", "░", "▒", "▓", "█", "█"];
	auto pixels = new float[256*256];

	auto n2d = new Noise2DContext(0);
	foreach (i; 0..100) {
		foreach (y; 0..256) {
			foreach (x; 0..256) {
				auto v = n2d.get(x * 0.1f, y * 0.1f) *
					0.5f + 0.5f;
				pixels[y*256+x] = v;
			}
		}
	}

	foreach (y; 0..256) {
		foreach (x; 0..256) {
			write(symbols[cast(int)(pixels[y*256+x] / 0.2f)]);
		}
		writeln();
	}
}
