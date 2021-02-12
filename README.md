# Star Relay Contract
- This is the very first version of start realy contract. A social media for good-cause charities. Remember ``Ice Bucket challenge`` ? So, you can simple start a challenge and set who can participate(or public) and how much is the entry fee (or also free) and then send you video.

## How to begin
    - git pull https://github.com/sesameJar/denver-contracts.git
    - npm i
    - ganache-cli
    - truffle migrate --network development --reset
    - truffle console --network development

## What we used
    - Truffle
    - Open Zepplin's test helpers
    - Open Zeppelin Safe Math
    - we also tried to use ```ChainLink``` for sending a ```GET``` request. But even their example did not work. We reached them out on slack but no much helpful. After two days we left if in ```chainLink``` branch.
***

### Roadmap
    - Issue an erc-721 for each challenge
    - instead of funding the last participant in each challenge, fund the person with highest likes. For that we still need to work on `CainLink`. 
    
