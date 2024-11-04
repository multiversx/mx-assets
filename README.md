# Introduction

This repository holds a list of branded assets in the Guilds Dapp. Branded Guilds can have website and socials URLS, a logo or a description, that will be displayed on MultiversX and xMoney products, such as the MultiversX Explorer, Web Wallet, and xPortal App.

# Guilds branding

Amplify your Guild brand via the Guilds, MultiversX Network web tools & the Mobile Wallet.

Add a logo, description & socials for your Guild.

Project owners can create a PR against this repo. Create a folder named exactly as your GUILD Contract Address. Add 2 files for the logo: `logo.png` and `logo.svg`. Also, add an `info.json` file containing all the relevant information.


| :exclamation:  Be aware of the repository's [environments](#environments) and [ownership checks](#ownership-checks). |
|----------------------------------------------------------------------------------------------------------------------|

## info.json

Here’s a prefilled template for the .json file to get you started:

```JSON
{
    "website": "https://www.guild.com",
    "description": "The EGLD token is the utility token of MultiversX Token",
    "name": "",
    "social": {
        "email": "egld-token@multiversx.com",
        "blog": "https://www.multiversxtoken.com/EGLD-token-blog",
        "twitter": "https://twitter.com/EGLD-token-twitter",
        "whitepaper": "https://www.multiversxtoken.com/EGLD-token-whitepaper.pdf",
        "coinmarketcap": "https://coinmarketcap.com/currencies/EGLD-token",
        "coingecko": "https://www.coingecko.com/en/coins/EGLD-token"
    },
    "owner": "erd1...",
    "status": "active"
}
```

## Guidelines:
- logo does not resemble xMoney/MultiversX/Mobile Wallet logos or other trademarked visual identities
- PR files need to be named info.json, logo.svg and logo.png
- the PR title has to be the Guild name
- max pic size 100kb (.png)

## Logos general requirements

- must look good also when cropped as a circle
- must define a transparent background
- must have sufficiently good contrast both when rendered on a light background, as well as a dark background

## logo.png

- mandatory when opening a pull request
- must have a resolution of 200x200 pixels

| ![RIDE png](https://github.com/multiversx/mx-assets/blob/master/tokens/RIDE-7d18e9/logo.png?raw=true) |
| :---------------------------------------------------------------------------------------------------: |
|                                               *Example*                                               |

## logo.svg

- mandatory when opening a pull request
- must have a square format

| ![RIDE svg](https://github.com/multiversx/mx-assets/blob/master/tokens/RIDE-7d18e9/logo.svg?raw=true) |
| :---------------------------------------------------------------------------------------------------: |
|                                               *Example*                                               |

# Ownership checks

To make sure that assets can only be branded by real owners, we introduced a GitHub action that requires that an ownership check is successful before allowing the PR to be merged.

This is done via a message signature verification, where the message is the latest commit sha of the PR (to avoid multiple signs in case of intermediary merges, if one of the signatures is verified, it is enough).

To do so, on the PR page, go to the `Commits` tab of the Pull Request and copy the latest commit hash (should look similar to `9c6164f1b195ce96bc5b65d6878ebe813e852550`). Then sign 
that string by using the owner of the asset you are branding. The easiest way is to use our [Utils Dapp](https://utils.multiversx.com) where you should log in with the owner wallet
and then go to the 'Sign Message' tab and sign the commit hash previously copied. After that, leave a comment inside the Pull Request with the obtained signature.
