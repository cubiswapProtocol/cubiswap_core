pragma solidity =0.6.12;

import '../interface/ICubiSwapFactory.sol';
import './CubiSwapPair.sol';

contract CubiSwapFactory is ICubiSwapFactory {
    address public override feeTo;
    address public override feeToSetter;
    bytes32 public initCodeHash;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        initCodeHash = keccak256(abi.encodePacked(type(CubiSwapPair).creationCode));
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(CubiSwapPair).creationCode);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public override pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'CubiSwapFactory: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CubiSwapFactory: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) public override view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(token0, token1)),
                initCodeHash
            ))));
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'CubiSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CubiSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'CubiSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(CubiSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        CubiSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getSalt() public view returns(bytes32) {
        bytes memory bytecode = type(CubiSwapPair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'CubiSwap: FORBIDDEN');
        feeTo = _feeTo;
    }


    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'CubiSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}
