open System

type Vec2 = struct
    val X : single
    val Y : single
    new(x, y) = { X = x; Y = y }
end

let inline lerp a b v = a * (1.0f - v) + b * v
let inline smooth v = v * v * (3.0f - 2.0f * v)
let inline gradient (o : Vec2) (g : Vec2) (p : Vec2) = g.X * (p.X - o.X) + g.Y * (p.Y - o.Y)

let random_gradient (rnd : Random) =
    let v = rnd.NextDouble() * Math.PI * 2.0
    Vec2(single (Math.Cos v), single (Math.Sin v))

// is there a better way to ignore function argument?
let random_vectors n (rnd : Random) = Array.init n (fun _ -> random_gradient rnd)

// is there a better way to generate permutations?
let random_permutations n (rnd : Random) =
    let perm = Array.init n id
    for i = 0 to n - 1 do
        let j = rnd.Next(i + 1)
        perm.[i] <- perm.[j]
        perm.[j] <- i
    perm

type Noise2DContext(seed) =
    let rgradients, permutations =
        let rnd = new Random(seed)
        (random_vectors 256 rnd, random_permutations 256 rnd)

    let gradients = Array.zeroCreate<Vec2> 4
    let origins = Array.zeroCreate<Vec2> 4

    member inline private this.get_gradient x y =
        let idx = permutations.[x &&& 255] + permutations.[y &&& 255]
        rgradients.[idx &&& 255]

    member inline private this.get_gradients_and_origins x y =
        let x0f = single (Math.Floor(double x))
        let y0f = single (Math.Floor(double y))
        let x0 = int x0f
        let y0 = int y0f
        let x1 = x0 + 1
        let y1 = y0 + 1
        gradients.[0] <- this.get_gradient x0 y0
        gradients.[1] <- this.get_gradient x1 y0
        gradients.[2] <- this.get_gradient x0 y1
        gradients.[3] <- this.get_gradient x1 y1
        origins.[0] <- Vec2(x0f + 0.0f, y0f + 0.0f)
        origins.[1] <- Vec2(x0f + 1.0f, y0f + 0.0f)
        origins.[2] <- Vec2(x0f + 0.0f, y0f + 1.0f)
        origins.[3] <- Vec2(x0f + 1.0f, y0f + 1.0f)

    member this.Get (x : single) (y : single) =
        let p = Vec2(x, y)
        this.get_gradients_and_origins x y
        let v0 = gradient origins.[0] gradients.[0] p
        let v1 = gradient origins.[1] gradients.[1] p
        let v2 = gradient origins.[2] gradients.[2] p
        let v3 = gradient origins.[3] gradients.[3] p
        let fx = smooth (x - origins.[0].X)
        let vx0 = lerp v0 v1 fx
        let vx1 = lerp v2 v3 fx
        let fy = smooth (y - origins.[0].Y)
        lerp vx0 vx1 fy

let symbols = [| ' '; '░'; '▒'; '▓'; '█'; '█' |]
let n2d = new Noise2DContext(int DateTime.Now.Ticks)
let pixels = Array.zeroCreate<single> (256 * 256)

for i = 1 to 100 do
    for y = 0 to 255 do
        for x = 0 to 255 do
            let v = n2d.Get (single x * 0.1f) (single y * 0.1f) * 0.5f + 0.5f
            pixels.[y * 256 + x] <- v
for y = 0 to 255 do
    for x = 0 to 255 do
        let idx = int (pixels.[y * 256 + x] / 0.2f)
        Console.Write symbols.[idx]
    Console.WriteLine()
