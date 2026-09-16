#!/usr/bin/env bash

# potemkin — generate an imagined web page from a URL using an LLM.
#
# Usage:
#   fakeweb URL [YEAR]
#
# Examples:
#   potemkin https://apple.com
#   potemkin https://apple.com 2001
#   potemkin https://amazon.com/dilithium-crystals 2267
#
# Output is a self-contained HTML document on stdout.

set -o pipefail

usage()
{
    printf 'usage: %s URL [YEAR]\n' "${0##*/}" >&2
    exit 2
}

(( $# >= 1 && $# <= 2 )) || usage

url=$1
year=${2-}

# Require an HTTP(S) URL with a nonempty host.
if [[ ! $url =~ ^https?://[^/[:space:]]+(/[^[:space:]]*)?$ ]]; then
    printf '%s: invalid URL: %s\n' "${0##*/}" "$url" >&2
    exit 2
fi

# A year is optional, but if supplied must be a plausible integer year.
if [[ -n $year ]]; then
    if [[ ! $year =~ ^[0-9]{1,4}$ ]] || (( 10#$year < 1 )); then
        printf '%s: invalid year: %s\n' "${0##*/}" "$year" >&2
        exit 2
    fi
fi

system_prompt='
You are Potemkin, a zero-internet generative web browser.

Given a URL, generate the web resource that plausibly exists at that URL.
Do not access the internet.

Generate a complete, self-contained HTML document suitable for rendering
directly in a modern browser.

Embed all CSS, JavaScript, and SVG in the document.
Do not depend on external stylesheets, scripts, fonts, images, or other resources.

Infer the site, page, content, visual design, and behavior from the URL and
your existing knowledge. When a year is specified, reconstruct or imagine
the page according to the web conventions, technology, content, and visual
design appropriate to that year.

The result is a simulation, not a claim that the generated page historically
existed exactly as shown.

Return only the HTML document.
Do not explain your choices.
Do not use Markdown fences.
Begin with <!doctype html>.
'

if [[ -n $year ]]; then
    prompt=$(printf 'URL: %s\nYear: %s\n' "$url" "$year")
else
    prompt=$(printf 'URL: %s\n' "$url")
fi

ask "$prompt" --system "$system_prompt" |
    answer
