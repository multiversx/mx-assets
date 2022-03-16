import os
import requests
import shutil

def clean(dir, api_url):
  tokens = os.listdir(dir)
  for token in tokens:
    if not os.path.isdir(dir + "/" + token):
      continue

    token_response = requests.head(api_url + '/tokens/' + token)
    if token_response.status_code == 200:
      continue

    collection_response = requests.head(api_url + '/collections/' + token)
    if collection_response.status_code == 200:
      continue

    shutil.rmtree(dir + "/" + token)
    print("Removed token " + token  + " " + dir + "/" + token)

clean("../tokens", "https://api.elrond.com")
clean("../testnet/tokens", "https://testnet-api.elrond.com")
clean("../devnet/tokens", "https://devnet-api.elrond.com")
  

