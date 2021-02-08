const RelayStar = artifacts.require("RelayStar");


module.exports = async function (deployer) {
  deployer.deploy(RelayStar)
}