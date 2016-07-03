const lerp = (a, b, v) => a * (1 - v) + b * v;
const smooth = v => v * v * (3 - 2 * v);
const gradient = (orig, grad, p) => grad.x * (p.x - orig.x) + grad.y * (p.y - orig.y);

function random_gradient() {
	const v = Math.random() * Math.PI * 2;
	return {x: Math.cos(v), y: Math.sin(v)};
}

class Noise2D {
	constructor() {
		this.rgradients = new Array(256);
		this.permutations = new Array(256);
		this.gradients = new Array(4);
		this.origins = new Array(4);

		for (let i = 0; i < 256; i++) {
			this.rgradients[i] = random_gradient();
		}
		for (let i = 0; i < 256; i++) {
			const j = Math.floor(Math.random() * i);
			this.permutations[i] = this.permutations[j];
			this.permutations[j] = i;
		}
	}

	get_gradient(x, y) {
		const idx = this.permutations[x & 255] + this.permutations[y & 255];
		return this.rgradients[idx & 255];
	}

	get_gradients_and_origins(x, y) {
		const x0 = Math.floor(x);
		const y0 = Math.floor(y);
		const x1 = x0 + 1;
		const y1 = y0 + 1;

		this.gradients[0] = this.get_gradient(x0, y0);
		this.gradients[1] = this.get_gradient(x1, y0);
		this.gradients[2] = this.get_gradient(x0, y1);
		this.gradients[3] = this.get_gradient(x1, y1);
		this.origins[0] = {x: x0 + 0, y: y0 + 0};
		this.origins[1] = {x: x0 + 1, y: y0 + 0};
		this.origins[2] = {x: x0 + 0, y: y0 + 1};
		this.origins[3] = {x: x0 + 1, y: y0 + 1};
	}

	get(x, y) {
		const p = {x, y};
		this.get_gradients_and_origins(x, y);
		const v1 = gradient(this.origins[0], this.gradients[0], p);
		const v2 = gradient(this.origins[1], this.gradients[1], p);
		const v3 = gradient(this.origins[2], this.gradients[2], p);
		const v4 = gradient(this.origins[3], this.gradients[3], p);
		const fx = smooth(x - this.origins[0].x);
		const vx1 = lerp(v1, v2, fx);
		const vx2 = lerp(v3, v4, fx);
		const fy = smooth(y - this.origins[0].y);
		return lerp(vx1, vx2, fy);
	}
}

const symbols = [' ', '░', '▒', '▓', '█', '█'];
const pixels = new Array(256*256);
const n2d = new Noise2D();

for (let i = 0; i < 100; i++) {
	for (let y = 0; y < 256; y++) {
		for (let x = 0; x < 256; x++) {
			const v = n2d.get(x * 0.1, y * 0.1) * 0.5 + 0.5;
			pixels[y*256+x] = v;
		}
	}
}

let output = '';
for (let y = 0; y < 256; y++) {
	for (let x = 0; x < 256; x++) {
		const idx = Math.floor(pixels[y*256+x] / 0.2);
		output += symbols[idx];
	}
	output += '\n';
}
process.stdout.write(output);
