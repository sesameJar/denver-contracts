const Challenge = artifacts.require("ChallengePlatform");


module.exports = async function (deployer) {
  deployer.deploy(Challenge)
}