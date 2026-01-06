const ViewingConditions = struct {
    n: f64,
    aw: f64,
    nbb: f64,
    ncb: f64,
    c: f64,
    nc: f64,
    rgbD: @Vector(3, f64),
    fl: f64,
    flRoot: f64,
    z: f64,

    fn make(whitePoint: @Vector(3, f64), adaptingLuminance: f64, backgroundLstar: f64, surround: f64, discountingIlluminant: bool) ViewingConditions {}
};
