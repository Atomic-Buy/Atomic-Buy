pod64: 
	cp ./pod64.circom ./test.circom
	circom test.circom --wasm --c --r1cs
wtns: 
	bash prepare.bash
key: 
	snarkjs groth16 setup test.r1cs ./p15.ptau test_0.zkey
	snarkjs zkey contribute test_0.zkey test_1.zkey --name="1st Contributor Name" -v -e="sdfasddfddfsfs"
	snarkjs zkey export verificationkey test_1.zkey verification_key.json
	
proof: 
	snarkjs groth16 prove test_1.zkey output.wtns proof.json public.json
 
verify: 
	snarkjs groth16 verify verification_key.json public.json proof.json
sol: 
	snarkjs zkey export solidityverifier test_1.zkey verify.sol         

clean: 
	rm -rf *_cpp *_js *.zkey *.r1cs *.wasm *.wtns public.json verification_key.json proof.json output.json test.circom 


