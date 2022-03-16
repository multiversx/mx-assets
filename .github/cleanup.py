from ast import Str
import os
import os
import requests
import shutil

def clean(dir, api_url):
  tokens = os.listdir(dir)
  for token in tokens:
    token_response = requests.head(api_url + '/tokens/' + token)
    nft_cresponse = requests.get(api_url + '/nfts?collection=' + token)
    if (token_response.status_code != 200 and nft_cresponse.json() == []): 
      shutil.rmtree(dir + "/" + token)
      print("Removed token " + token  + " " + dir + "/" + token)

clean("../tokens", "https://api.elrond.com")
clean("../testnet/tokens", "https://testnet-api.elrond.com")
clean("../devnet/tokens", "https://devnet-api.elrond.com")
  

