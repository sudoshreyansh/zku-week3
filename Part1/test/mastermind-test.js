const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;

// defines the objects that we need for testing and working with circuit data - F1Field
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

function buildInput(guess, solution, hits, blows, salt, hash) {
    return {
        "pubGuessColorA": guess[0][0],
        "pubGuessColorB": guess[1][0],
        "pubGuessColorC": guess[2][0],
        "pubGuessShapeA": guess[0][1],
        "pubGuessShapeB": guess[1][1],
        "pubGuessShapeC": guess[2][1],
        "privSolnColorA": solution[0][0],
        "privSolnColorB": solution[1][0],
        "privSolnColorC": solution[2][0],
        "privSolnShapeA": solution[0][1],
        "privSolnShapeB": solution[1][1],
        "privSolnShapeC": solution[2][1],
        "pubNumHit": hits,
        "pubNumBlow": blows,
        "privSalt": salt,
        "pubSolnHash": hash
    }  
}

describe("MastermindVariation", function () {
    this.timeout(100000000);
    let circuit;
    let poseidon;
    let F;

    before(async () => {
        poseidon = await buildPoseidon();
        F = poseidon.F;
        circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
    });

    it("should verify correctly for valid inputs", async function () {
        const guess = [[0, 0], [1, 1], [2, 2]];
        const solution = [[1, 1], [0, 0], [2, 2]];
        const blows = 2;
        const hits = 1;
        const salt = 0;
        const hash = poseidon([salt, ...solution.flat()]);
        const hashBN = F.toObject(hash);
        
        const INPUT = buildInput(guess, solution, hits, blows, salt, hashBN);
        const witness = await circuit.calculateWitness(INPUT, true);

        // check the output solution hash
        assert(F.eq(F.e(hash), F.e(witness[1])));
    });

    it("should fail for out of range choice", async function () {
        const guess = [[0, 0], [1, 1], [2, 2]];
        const solution = [[100, 100], [1, 1], [2, 2]];
        const blows = 0;
        const hits = 2;
        const salt = 0;
        const hash = F.toObject(poseidon([salt, ...solution.flat()]));
        
        const INPUT = buildInput(guess, solution, hits, blows, salt, hash);

        try {
            const witness = await circuit.calculateWitness(INPUT, true);
            assert.fail()
        } catch (e) {
            assert(true);
        }
    });

    it("should fail if blows/hits count is wrong", async function () {
        const guess = [[0, 0], [1, 1], [2, 2]];
        const solution = [[0, 0], [1, 1], [2, 2]];
        const blows = 1;
        const hits = 2;
        const salt = 0;
        const hash = F.toObject(poseidon([salt, ...solution.flat()]));
        
        const INPUT = buildInput(guess, solution, hits, blows, salt, hash);

        try {
            const witness = await circuit.calculateWitness(INPUT, true);
            assert.fail()
        } catch (e) {
            assert(true);
        }
    });

    it("should fail for duplicate choice", async function () {
        const guess = [[0, 0], [1, 1], [2, 2]];
        const solution = [[0, 0], [0, 0], [2, 2]];
        const blows = 0;
        const hits = 3;
        const salt = 0;
        const hash = F.toObject(poseidon([salt, ...solution.flat()]));
        
        const INPUT = buildInput(guess, solution, hits, blows, salt, hash);

        try {
            const witness = await circuit.calculateWitness(INPUT, true);
            assert.fail();
        } catch (e) {
            assert(true);
        }
    });

    it("should fail for invalid solution hash", async function () {
        const guess = [[0, 0], [1, 1], [2, 2]];
        const solution = [[0, 0], [1, 1], [2, 2]];
        const blows = 0;
        const hits = 3;
        const salt = 0;
        const hash = BigInt(0);
        
        const INPUT = buildInput(guess, solution, hits, blows, salt, hash);

        try {
            const witness = await circuit.calculateWitness(INPUT, true);
            assert.fail()
        } catch (e) {
            assert(true);
        }
    });
});