pragma circom 2.0.3;

/*

0-12  = clubs
13-25 = diamonds
26-38 = hearts
39-51 = spades

in1 = previousCard
in2 = nextCard

*/

template isSameSuite () {
    signal input in1;
    signal input in2;
    
    signal output out;
    
    var sameSuite;


    assert(in1 != in2);

    // check if both cards are clubs
    if (in1 >= 0 && in1 < 13 && in2 >= 0 && in2 < 13) {
        sameSuite = 1;
    }
    // check if both cards are diamonds
    if (in1 >= 13 && in1 < 26 && in2 >= 13 && in2 < 26) {
        sameSuite = 1;
    }
    // check if both cards are hearts
    if (in1 >= 26 && in1 < 39 && in2 >= 26 && in2 < 39) {
        sameSuite = 1;
    }
    // check if both cards are spades
    if (in1 >= 39 && in1 < 52 && in2 >= 39 && in2 < 52) {
        sameSuite = 1;
    }
    assert(sameSuite == 1);
    out <== 1;
}

component main = isSameSuite();

/* INPUT = {
    "in1": "0",
    "in2": "10"
} */