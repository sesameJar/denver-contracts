const StarRelay = artifacts.require("StarRelay");


module.exports = async function (deployer) {
  deployer.deploy(StarRelay)
}