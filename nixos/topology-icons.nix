# Extra nix-topology icons from https://github.com/homarr-labs/dashboard-icons.
# nix-topology accepts absolute paths as icons, so use them as `icon = "${icons.docker}";`.
# Its renderer inlines SVGs by splitting on the literal "<svg " and prints title/metadata/desc as text,
# so the opening tag gets normalized and those elements stripped.
# Add one by prefetching it: nix-prefetch-url <url> | xargs nix hash to-sri --type sha256
{
  fetchurl,
  perl,
  runCommand,
}:
let
  rev = "f1d048d9885b97a7319e0a51e508217459f212df";
in
builtins.mapAttrs
  (
    name: hash:
    runCommand "${name}.svg"
      {
        src = fetchurl {
          url = "https://raw.githubusercontent.com/homarr-labs/dashboard-icons/${rev}/svg/${name}.svg";
          inherit hash;
        };
        nativeBuildInputs = [ perl ];
      }
      ''
        sed -z -e 's/<svg[[:space:]]\+/<svg /' -e 's|<title[^>]*>[^<]*</title>||g' -e 's|<metadata.*</metadata>||' -e 's|<desc[^>]*>[^<]*</desc>||g' "$src" \
          | perl -0pe 's{<svg ([^>]*)>}{my $a = $1; if ($a =~ /viewBox="[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)"/) { my $w = 96 * $1 / $2; $a =~ s/\s*\b(?:width|height)="[^"]*"//g; $a .= sprintf(q{ width="%g" height="96"}, $w) } "<svg $a>"}e' > "$out"
      ''
  )
  {
    alertmanager = "sha256-/BSpgNltKdMwwCWzA3zCeSNaG/JtEPS/H3lvnDTxSIg=";
    borgmatic = "sha256-L7uJxq2d8vyTGcD96t5eAFr6A+yjskHFbj8pqwgEDjA=";
    arch-linux = "sha256-AvXJjKWEYvILkMP59LDr0hnmUJATCIVSR6J8fNt3f6E=";
    cloudflare = "sha256-jRiABG7SI/+0ymYNT1LP+YbW2zEOJdh82C7M0CS0YfU=";
    cloudflared = "sha256-Modr2oFUIgMxbWe5YjgYrGCYaJfKx59w4D6PMfe38WA=";
    discourse = "sha256-4Z+0bEjoaKLPJcniAMsU1cCaKZ45UJ6CaRs/YtZyRMI=";
    docker = "sha256-feReHqID2jKgQMJX9HzTmlcRs6IA0n7HLbzLxe+xWQs=";
    garuda-linux = "sha256-Ri/Bb39LRze1U/B1PXgQThqSon+t8hCQ916PEhUuJ0k=";
    github-light = "sha256-/z0Yv50GoifM/VVpdLL880T4Mz/lKGOlJcvV5D/eoAQ=";
    gitlab = "sha256-9xQtdvrDwjsIrme5mUoG+n3553Z4Hfa1+xugMPmhIRE=";
    google = "sha256-to4BoN0rDMajvLnWFBnzmnci3YhRe/vykEIUpthKovM=";
    hetzner = "sha256-rlKblUhqUquy74ECbD8Y+jLJt/kUtNJcJskcmbJfedY=";
    google-translate = "sha256-z5XhmBh6C5H41B2+LFIBgHE+OGPcQhAIq2x3plPFBfc=";
    matterbridge = "sha256-lUYgqihfCwxoG/er+OVwUnq982CBDsyjyvzhPn2wBzk=";
    n8n = "sha256-RbKCEI9gsS32y6aOP6Yz1Wlw6rTSrGse70OmC16imvU=";
    postfix = "sha256-+RTkVvX482iKxLpxXCOV1j09+cXadaojtyMBcBmr0Q0=";
    privatebin = "sha256-YnhLmXNOxUjRQVMECAbfJLo5XFdB2KcOFmbO/BI4Des=";
    redis = "sha256-nD1KZFgJRoelsDWx2JC4CLPW0GWEYl4MvjgFTSTjuG0=";
    roundcube = "sha256-g/2/CnGic7OKXwh041ZfCgAK5dADEBW5c9Q6tdpRPaw=";
    syncthing = "sha256-ZdFDD3UivqBQclmSnwAz18YlOdFHV9fG9bYldOtNotM=";
    watchtower = "sha256-khCPmuN3tLNO9LiVN+JMZDLUmyjYznQzw9y1YnPpuJY=";
    wikijs = "sha256-XWqUpN5/c+edmXgGPAX56vua0NOMN5hwJnZiu6njTFk=";
  }
