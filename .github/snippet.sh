DIR=""

validate_filenames() {
  ADDED_FILES=$@
  for file in $ADDED_FILES; do
    if [[ ${file} != *"/info.json"* && ${file} != *"/logo.png"* && ${file} != *"/logo.svg"* ]]; then
      echo "Filename ${file} isn't expected!"
      exit 1
    fi

    DIR=`basename $(dirname $file)`
  done
}

validate_file_size() {
  ADDED_FILES=$@
  for file in $ADDED_FILES; do
    file_size_kb=$(ls -s --block-size=K ${file} | grep -o -E '^[0-9]+')

    if [[ ${file_size_kb} -gt 64 ]]; then
      echo "File ${file} is too large! (${file_size_kb} KB)"
      exit 1
    fi
  done
}

validate_png_dimensions() {
  ADDED_FILES=$@
  EXPECTED_PNG_DIMENSIONS="200x200"

  for file in $ADDED_FILES; do
    if [[ ${file} == *"/logo.png"* ]]; then 
      png_dimensions=$(identify $file | grep -E -o "[0-9]+x[0-9]+" | head -1)

      if [[ $png_dimensions != $EXPECTED_PNG_DIMENSIONS ]]; then
        echo "Invalid dimensions for PNG! ( $png_dimensions )"
        exit 1
      fi
    fi
  done
}

validate_token_existence() {
  urls=( "https://api.elrond.com/" "https://testnet-api.elrond.com/" "https://devnet-api.elrond.com/")
  for url in ${urls[@]}; do
    API_TOKEN_URL="$url" 
    API_TOKEN_URL+="tokens/"
    API_TOKEN_URL+="$DIR"
    API_COLLECTION_URL="$url"
    API_COLLECTION_URL+="collections/"
    API_COLLECTION_URL+="$DIR"

    HTTP_STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$API_TOKEN_URL")
    if [[ ${HTTP_STATUS} == 200 ]]; then
      exit 0
    fi
    echo "Failed fetching from $API_TOKEN_URL"
    
    HTTP_STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$API_COLLECTION_URL")
    if [[ ${HTTP_STATUS} == 200 ]]; then
      exit 0
    fi
    echo "Failed fetching from $API_COLLECTION_URL"
  done

  echo "Invalid token $DIR"
  exit 1
}