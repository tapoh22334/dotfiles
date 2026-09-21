"""A tiny YAML reader for ticket manifests, so the skill has no install step.

Supports exactly what the manifest schema uses: nested mappings, lists of
mappings, scalars, and block scalars (`|` / `|-`) for issue bodies. It is not a
general YAML implementation -- if PyYAML is present, apply.sh prefers it.

Deliberately rejects what it cannot parse rather than guessing, because a
manifest silently misread would create wrong issues on GitHub, which is exactly
the class of failure this whole script exists to prevent.
"""


def _scalar(tok: str):
    tok = tok.strip()
    if not tok:
        return ""
    if len(tok) >= 2 and tok[0] == tok[-1] and tok[0] in "\"'":
        return tok[1:-1]
    if tok in ("true", "True"):
        return True
    if tok in ("false", "False"):
        return False
    if tok in ("null", "~"):
        return None
    if tok.lstrip("-").isdigit():
        return int(tok)
    return tok


def _strip_comment(line: str) -> str:
    out, quote = [], None
    for ch in line:
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def load(text: str):
    raw = text.replace("\t", "  ").split("\n")

    # (indent, content) for real lines; block scalars are folded in below.
    lines = []
    i = 0
    while i < len(raw):
        line = raw[i]
        stripped = _strip_comment(line)
        if not stripped.strip():
            i += 1
            continue
        indent = len(stripped) - len(stripped.lstrip())
        content = stripped.strip()

        if content.endswith(("|", "|-", ">", ">-")):
            key = content.rsplit(":", 1)[0].strip() if ":" in content else content
            chomp = content.endswith("-")
            body, j = [], i + 1
            base = None
            while j < len(raw):
                nxt = raw[j]
                if not nxt.strip():
                    body.append("")
                    j += 1
                    continue
                ind = len(nxt) - len(nxt.lstrip())
                if ind <= indent:
                    break
                base = ind if base is None else min(base, ind)
                body.append(nxt)
                j += 1
            base = base or 0
            joined = "\n".join(b[base:] if len(b) >= base else b for b in body)
            joined = joined.rstrip("\n") if chomp else joined.rstrip("\n") + "\n"
            lines.append((indent, key, joined, True))
            i = j
            continue

        lines.append((indent, content, None, False))
        i += 1

    pos = [0]

    def parse_block(indent):
        # A block is either a list (lines starting "- ") or a mapping.
        if pos[0] >= len(lines):
            return {}
        if lines[pos[0]][1].startswith("- "):
            return parse_list(indent)
        return parse_map(indent)

    def parse_list(indent):
        items = []
        while pos[0] < len(lines):
            ind, content, block, is_block = lines[pos[0]]
            if ind < indent or not content.startswith("- "):
                break
            rest = content[2:].strip()
            pos[0] += 1
            if ":" in rest and not rest.startswith(("\"", "'")):
                k, _, v = rest.partition(":")
                item = {}
                if v.strip():
                    item[k.strip()] = _scalar(v)
                else:
                    nested_indent = lines[pos[0]][0] if pos[0] < len(lines) else ind + 2
                    item[k.strip()] = parse_block(nested_indent)
                # remaining keys of this list item sit deeper than the dash
                while pos[0] < len(lines) and lines[pos[0]][0] > ind:
                    item.update(parse_map(lines[pos[0]][0], stop_at=ind))
                items.append(item)
            else:
                items.append(_scalar(rest))
        return items

    def parse_map(indent, stop_at=None):
        node = {}
        while pos[0] < len(lines):
            ind, content, block, is_block = lines[pos[0]]
            if ind < indent:
                break
            if stop_at is not None and ind <= stop_at:
                break
            if content.startswith("- "):
                break
            if ":" not in content and not is_block:
                raise ValueError(f"cannot parse line: {content!r}")
            if is_block:
                node[content.rstrip(":").strip()] = block
                pos[0] += 1
                continue
            key, _, val = content.partition(":")
            key, val = key.strip(), val.strip()
            pos[0] += 1
            if val:
                node[key] = _scalar(val)
            else:
                nxt = lines[pos[0]][0] if pos[0] < len(lines) else indent
                node[key] = parse_block(nxt) if nxt > ind else None
        return node

    return parse_block(lines[0][0]) if lines else {}
