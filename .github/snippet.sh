# Validation helpers used by .github/workflows/validate.yml.
# Usage: source .github/snippet.sh; validate_<check> <changed files...>
# Each function checks every file it is given, reports all problems, and
# returns non-zero if any check failed (it never exits the calling shell).

SIZE_LIMIT_KB=100
EXPECTED_PNG_DIMENSIONS="200 x 200"

# True for logos/icons that the image checks apply to.
is_asset_image() {
  [[ $1 == *tokens/*/logo.png || $1 == *tokens/*/logo.svg ||
     $1 == *identities/*/logo.png || $1 == *identities/*/logo.svg ||
     $1 == *accounts/*/*.png || $1 == *accounts/*/*.svg ]]
}

validate_filenames() {
  local failed=0
  for file in "$@"; do
    echo "Checking filename for $file"
    if [[ ${file} != *"/info.json"* && ${file} != *"/logo.png"* && ${file} != *"/logo.svg"* && ${file} != *"accounts/"* && ${file} != *".github/"* && ${file} != *"/ranks.json"* && ${file} != *"README.md"* && ${file} != "CLAUDE.md" ]]; then
      echo "Filename ${file} isn't expected!"
      failed=1
    fi
  done
  return $failed
}

validate_file_size() {
  local failed=0
  for file in "$@"; do
    [[ -f $file ]] && is_asset_image "$file" || continue
    echo "Checking file size for $file"
    local size_bytes
    size_bytes=$(wc -c < "$file" | tr -d ' ')
    if (( size_bytes > SIZE_LIMIT_KB * 1024 )); then
      echo "File ${file} is too large! ($(( (size_bytes + 1023) / 1024 )) KB, limit is ${SIZE_LIMIT_KB} KB)"
      failed=1
    fi
  done
  return $failed
}

# Prints the root <svg> tag's "width height", taken from its viewBox when present,
# otherwise from its width/height attributes. Prints nothing if neither is usable.
svg_dimensions() {
  local svg_tag view_box width height
  svg_tag=$(tr '\n\r\t' '   ' < "$1" | grep -o -E '<svg[^>]*>' | head -1)
  view_box=$(echo "$svg_tag" | grep -o -E "viewBox=[\"'][^\"']*[\"']" | head -1 | sed -E "s/^viewBox=[\"']//; s/[\"']$//" | tr ',' ' ')
  if [[ -n $view_box ]]; then
    echo "$view_box" | awk 'NF == 4 { print $3, $4 }'
    return
  fi
  width=$(echo "$svg_tag" | grep -o -E "[[:space:]]width=[\"'][0-9.]+(px)?[\"']" | head -1 | grep -o -E '[0-9.]+' | head -1)
  height=$(echo "$svg_tag" | grep -o -E "[[:space:]]height=[\"'][0-9.]+(px)?[\"']" | head -1 | grep -o -E '[0-9.]+' | head -1)
  if [[ -n $width && -n $height ]]; then
    echo "$width $height"
  fi
}

validate_svg_square() {
  local failed=0
  for file in "$@"; do
    [[ -f $file && $file == *.svg ]] && is_asset_image "$file" || continue
    echo "Checking if SVG is square for $file"
    local dimensions width height
    dimensions=$(svg_dimensions "$file")
    if [[ -z $dimensions ]]; then
      echo "Could not read dimensions of ${file}: the root <svg> needs a viewBox (or numeric width and height)"
      failed=1
      continue
    fi
    IFS=' ' read -r width height <<< "$dimensions"
    echo "Width:$width Height:$height"
    # Allow 1% difference so exporter rounding (e.g. 150 vs 149.999998) passes.
    if ! awk -v w="$width" -v h="$height" 'BEGIN { w += 0; h += 0; d = w - h; if (d < 0) d = -d; exit !(w > 0 && h > 0 && d <= 0.01 * (w > h ? w : h)) }'; then
      echo "SVG not a square! ( w:$width h:$height )"
      failed=1
    fi
  done
  return $failed
}

validate_png_dimensions() {
  local failed=0
  for file in "$@"; do
    [[ -f $file && $file == *.png ]] && is_asset_image "$file" || continue
    echo "Checking PNG dimensions for $file"
    local png_dimensions
    png_dimensions=$(file "$file" | grep -E -o "[0-9]+ x [0-9]+" | head -1)
    echo "PNG dimensions: $png_dimensions"
    if [[ $png_dimensions != "$EXPECTED_PNG_DIMENSIONS" ]]; then
      echo "Invalid dimensions for PNG ${file}! ( ${png_dimensions:-unreadable}, expected $EXPECTED_PNG_DIMENSIONS )"
      failed=1
    fi
  done
  return $failed
}

# Checks that every token folder touched by the changed files exists as a token
# or collection on the API of the environment the folder belongs to.
validate_token_existence() {
  local failed=0 checked=" "
  for file in "$@"; do
    local api_url token_id
    file=${file#./}
    case $file in
      tokens/*/*)         api_url="https://api.multiversx.com" ;;
      testnet/tokens/*/*) api_url="https://testnet-api.multiversx.com" ;;
      devnet/tokens/*/*)  api_url="https://devnet-api.multiversx.com" ;;
      *) continue ;;
    esac
    token_id=$(echo "$file" | sed -E 's#^((testnet|devnet)/)?tokens/([^/]+)/.*#\3#')
    [[ $checked == *" $api_url/$token_id "* ]] && continue
    checked+="$api_url/$token_id "

    echo "Checking that $token_id exists on $api_url"
    local endpoint status found=0
    for endpoint in tokens collections; do
      status=$(curl -s -o /dev/null -w "%{http_code}" --retry 3 --retry-all-errors --max-time 30 "$api_url/$endpoint/$token_id" || true)
      if [[ $status == 200 ]]; then
        found=1
        break
      fi
      echo "  $api_url/$endpoint/$token_id returned HTTP $status"
    done
    if (( ! found )); then
      echo "Invalid token $token_id: not found as a token or collection on $api_url"
      failed=1
    fi
  done
  return $failed
}
