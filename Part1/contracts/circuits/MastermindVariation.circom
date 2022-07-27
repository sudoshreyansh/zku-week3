pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/gates.circom";

template EqualOptions() {
    signal input in[2][2];
    signal output out;

    component equalInputs[2];
    component andInputs;
    var i;

    for ( i = 0; i < 2; i++ ) {
        equalInputs[i] = IsEqual();
        equalInputs[i].in[0] <== in[0][i];
        equalInputs[i].in[1] <== in[1][i];
    }

    andInputs = AND();
    andInputs.a <== equalInputs[0].out;
    andInputs.b <== equalInputs[1].out;
    out <== andInputs.out;
}

// This is the Royale Mastermind version of Mastermind
// It has 5 colors x 5 shapes and 3 holes
template MastermindVariation() {
    // Public inputs
    signal input pubGuessColorA;
    signal input pubGuessColorB;
    signal input pubGuessColorC;
    signal input pubGuessShapeA;
    signal input pubGuessShapeB;
    signal input pubGuessShapeC;
    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnColorA;
    signal input privSolnColorB;
    signal input privSolnColorC;
    signal input privSolnShapeA;
    signal input privSolnShapeB;
    signal input privSolnShapeC;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[3][2] = [[pubGuessColorA, pubGuessShapeA], [pubGuessColorB, pubGuessShapeB], [pubGuessColorC, pubGuessShapeC]];
    var soln[3][2] =  [[privSolnColorA, privSolnShapeA], [privSolnColorB, privSolnShapeB], [privSolnColorC, privSolnShapeC]];
    var i = 0;
    var j = 0;
    var k = 0;
    component lessThan[12];
    component equalGuess[3];
    component equalSoln[3];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 5 (0-4).
    for (j=0; j<3; j++) {
        for (i=0; i<2; i++) {
            var t = 2*j+i;
            lessThan[t] = LessThan(4);
            lessThan[t].in[0] <== guess[j][i];
            lessThan[t].in[1] <== 10;
            lessThan[t].out === 1;
            lessThan[t+6] = LessThan(4);
            lessThan[t+6].in[0] <== soln[j][i];
            lessThan[t+6].in[1] <== 10;
            lessThan[t+6].out === 1;
        }

        for (k=j+1; k<3; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = EqualOptions();
            equalSoln[equalIdx] = EqualOptions();
            
            for (i=0; i<2; i++) {
                equalGuess[equalIdx].in[0][i] <== guess[j][i];
                equalGuess[equalIdx].in[1][i] <== guess[k][i];
                equalSoln[equalIdx].in[0][i] <== soln[j][i];
                equalSoln[equalIdx].in[1][i] <== soln[k][i];
            }

            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx].out === 0;

            equalIdx += 1;
        }
    }

    // Count hit & blow
    var hit = 0;
    var blow = 0;
    component equalHB[9];

    for (j=0; j<3; j++) {
        for (k=0; k<3; k++) {
            equalHB[3*j+k] = EqualOptions();
            equalHB[3*j+k].in[0][0] <== soln[j][0];
            equalHB[3*j+k].in[0][1] <== soln[j][1];
            equalHB[3*j+k].in[1][0] <== guess[k][0];
            equalHB[3*j+k].in[1][1] <== guess[k][1];
            blow += equalHB[3*j+k].out;
            if (j == k) {
                hit += equalHB[3*j+k].out;
                blow -= equalHB[3*j+k].out;
            }
        }
    }

    // Create a constraint around the number of hit
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // Create a constraint around the number of blow
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(7);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnColorA;
    poseidon.inputs[2] <== privSolnShapeA;
    poseidon.inputs[3] <== privSolnColorB;
    poseidon.inputs[4] <== privSolnShapeB;
    poseidon.inputs[5] <== privSolnColorC;
    poseidon.inputs[6] <== privSolnShapeC;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
 }

 component main {public [pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessShapeA, pubGuessShapeB, pubGuessShapeC, pubNumHit, pubNumBlow, pubSolnHash]} = MastermindVariation();