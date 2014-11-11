import java.util.Random;

public class test {
	private static class Noise2DContext {
		private int[] permutations;
		
		// interleaved x and y fields (SOA vs AOS)
		private float[] rgradients;
		private float[] gradients;
		private float[] origins;
		
		private float lerp(float a, float b, float v) {
			return a * (1 - v) + b * v;
		}
		
		private float smooth(float v) {
			return v * v * (3 - 2 * v);
		}
		
		public Noise2DContext(int seed) {
			Random rnd = new Random(seed);
			rgradients = new float[256 * 2];
			permutations = new int[256];
			for (int i = 0; i < 256;) {
				double v = rnd.nextDouble() * Math.PI * 2.0;
				rgradients[i++] = (float) Math.cos(v);
				rgradients[i++] = (float) Math.sin(v);
			}
			for (int i = 0; i < 256; i++) {
				int j = rnd.nextInt(i + 1);
				permutations[i] = permutations[j];
				permutations[j] = i;
			}
			gradients = new float[4 * 2];
			origins = new float[4 * 2];
		}
		
		private int rgrad_idx(int x, int y) {
			return (permutations[x & 255] + permutations[y & 255]) & 255;
		}
		
		private void get_gradients(float x, float y) {
			float x0f = (float) Math.floor(x);
			float y0f = (float) Math.floor(y);
			int x0 = (int) x0f;
			int y0 = (int) y0f;
			int x1 = x0 + 1;
			int y1 = y0 + 1;
			
			int idx = rgrad_idx(x0, y0);
			gradients[0] = rgradients[idx];
			gradients[1] = rgradients[idx + 1];
			
			idx = rgrad_idx(x1, y0);
			gradients[2] = rgradients[idx];
			gradients[3] = rgradients[idx + 1];
			
			idx = rgrad_idx(x0, y1);
			gradients[4] = rgradients[idx];
			gradients[5] = rgradients[idx + 1];
			
			idx = rgrad_idx(x1, y1);
			gradients[6] = rgradients[idx];
			gradients[7] = rgradients[idx + 1];
			
			origins[0] = x0f + 0;
			origins[1] = y0f + 0;
			
			origins[2] = x0f + 1;
			origins[3] = y0f + 0;
			
			origins[4] = x0f + 0;
			origins[5] = y0f + 1;
			
			origins[6] = x0f + 1;
			origins[7] = y0f + 1;
		}
		
		private float gradient(int idx, float x, float y) {
			idx <<= 1;
			return gradients[idx] * (x - origins[idx]) + gradients[idx + 1] * (y - origins[idx + 1]);
		}
		
		public float get(float x, float y) {
			get_gradients(x, y);
			float v0 = gradient(0, x, y);
			float v1 = gradient(1, x, y);
			float v2 = gradient(2, x, y);
			float v3 = gradient(3, x, y);
			float fx = smooth(x - origins[0]);
			float vx0 = lerp(v0, v1, fx);
			float vx1 = lerp(v2, v3, fx);
			float fy = smooth(y - origins[1]);
			return lerp(vx0, vx1, fy);
		}
	}
	
	static char[] symbols = { ' ', '░', '▒', '▓', '█', '█' };
	
	public test() {
		Noise2DContext n2d = new Noise2DContext((int) System.currentTimeMillis());
		float[] pixels = new float[256 * 256];
		for (int i = 0; i < 100; i++) {
			for (int y = 0; y < 256; y++) {
				for (int x = 0; x < 256; x++) {
					float v = n2d.get(x * 0.1f, y * 0.1f) * 0.5f + 0.5f;
					pixels[y * 256 + x] = v;
				}
			}
		}
		
		for (int y = 0; y < 256; y++) {
			for (int x = 0; x < 256; x++) {
				int idx = (int) (pixels[y * 256 + x] / 0.2f);
				System.out.print(symbols[idx]);
			}
			System.out.println();
		}
	}
	
	public static void main(String[] args) {
		new test();
	}
}
