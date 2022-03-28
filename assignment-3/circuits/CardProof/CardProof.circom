pragma circom 2.0.3;

include "circuits/mimcsponge.circom";
include "circuits/comparators.circom";

template CardProof() {
    signal input suit;
    signal input value;

    signal output h;

    var suitN = 4;
    var valueN = 13;

    /* check suit < 4 */
    component comp1 = LessThan(32);
    comp1.in[0] <== suit;
    comp1.in[1] <== suitN;
    comp1.out === 1;

    /* check value < 13 */
    component comp2 = LessThan(32);
    comp2.in[0] <== value;
    comp2.in[1] <== valueN;
    comp2.out === 1;

    /* check MiMCSponge(suit, value) = commit */
    component mimc = MiMCSponge(2, 220, 1);

    mimc.ins[0] <== suit;
    mimc.ins[1] <== value;
    mimc.k <== 0;

    h <== mimc.outs[0];
}


component main = CardProof();

/* INPUT = {
    "suit": "3",
    "value": "7"
} */