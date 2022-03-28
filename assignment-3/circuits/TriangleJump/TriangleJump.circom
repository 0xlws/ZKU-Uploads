pragma circom 2.0.3;

include "circuits/comparators.circom";
// include "circomlib/comparators.circom";

template TriangleJump () {
    signal input Ax;
    signal input Ay;
    signal input Bx;
    signal input By;
    signal input Cx;
    signal input Cy;
    signal input energy;
    signal output three;
 
    // Calculation the area of
    // triangle. We have skipped
    // multiplication with 0.5
    // to avoid floating point
    // computations
    var a = Ax * (By - Cy)
            + Bx * (Cy - Ay)
            + Cx * (Ay - By);
    log(a);
    assert(a != 0);

    /* check (Bx-Ax)^2 (By-Ay)^2 < energy */
    component ltDistAB = LessThan(32);
    signal ABxDistSquare;
    signal AByDistSquare;
    signal diffABx;
    diffABx <== Bx - Ax;
    signal diffABy;
    diffABy <== By - Ay;
    ABxDistSquare <== diffABx * diffABx;
    AByDistSquare <== diffABy * diffABy;
    ltDistAB.in[0] <== ABxDistSquare + AByDistSquare;
    ltDistAB.in[1] <== energy * energy + 1;
    ltDistAB.out === 1;
    log(ltDistAB.out);

    /* check (Cx-Bx)^2 (Cy-By)^2 < energy */
    component ltDistBC = LessThan(32);
    signal BCxDistSquare;
    signal BCyDistSquare;
    signal diffBCx;
    diffBCx <== Cx - Bx;
    signal diffBCy;
    diffBCy <== Cy - By;
    BCxDistSquare <== diffBCx * diffBCx;
    BCyDistSquare <== diffBCy * diffBCy;
    ltDistBC.in[0] <== BCxDistSquare + BCyDistSquare;
    ltDistBC.in[1] <== energy * energy + 1;
    ltDistBC.out === 1;
    log(ltDistBC.out);


    /* check (Ax-Cx)^2 (Ay-Cy)^2 < energy */
    component ltDistCA = LessThan(32);
    signal ACxDistSquare;
    signal ACyDistSquare;
    signal diffACx;
    diffACx <== Ax - Cx;
    signal diffACy;
    diffACy <== Ay - Cy;
    ACxDistSquare <== diffACx * diffACx;
    ACyDistSquare <== diffACy * diffACy;
    ltDistCA.in[0] <== ACxDistSquare + ACyDistSquare;
    ltDistCA.in[1] <== energy * energy + 1;
    ltDistCA.out === 1;
    log(ltDistCA.out);

    three <== ltDistAB.out + ltDistBC.out + ltDistCA.out;


}


component main = TriangleJump();

/* INPUT = {
    "Ax": "1",
    "Ay": "1",    
    "Bx": "2",
    "By": "2",        
    "Cx": "3",
    "Cy": "3",    
    "energy": "10"
} */